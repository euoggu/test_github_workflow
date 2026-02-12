#!/usr/bin/env bash

set -euo pipefail

check_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "缺少命令: $cmd"
    exit 1
  fi
}

check_cmd gh
check_cmd jq
check_cmd ruby
check_cmd git
check_cmd open
check_cmd rg

if ! gh auth status >/dev/null 2>&1; then
  echo "gh 未登录，请先执行: gh auth login"
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "当前目录不是 git 仓库"
  exit 1
fi

repo="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
if [[ -z "$repo" ]]; then
  echo "无法识别 GitHub 仓库，请确认本地仓库已关联 GitHub remote"
  exit 1
fi

branch="$(git rev-parse --abbrev-ref HEAD)"

mapfile -t workflow_files < <(rg --files .github/workflows -g '*.yml' -g '*.yaml' | sort)
if [[ ${#workflow_files[@]} -eq 0 ]]; then
  echo "未找到 .github/workflows 下的 workflow 文件"
  exit 1
fi

dispatch_files=()
dispatch_names=()
for wf in "${workflow_files[@]}"; do
  if rg -q '^\s*workflow_dispatch\s*:' "$wf"; then
    dispatch_files+=("$wf")
    name="$(ruby -ryaml -e '
      file = ARGV[0]
      data = YAML.load_file(file) || {}
      puts(data["name"] || File.basename(file))
    ' "$wf" 2>/dev/null || basename "$wf")"
    dispatch_names+=("$name")
  fi
done

if [[ ${#dispatch_files[@]} -eq 0 ]]; then
  echo "没有可手动触发（workflow_dispatch）的 workflow"
  exit 1
fi

echo "可执行的 Action 列表:"
for i in "${!dispatch_files[@]}"; do
  idx=$((i + 1))
  printf "%2d) %s [%s]\n" "$idx" "${dispatch_names[$i]}" "${dispatch_files[$i]}"
done

while true; do
  read -r -p "请选择要执行的 Action 编号: " choice
  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#dispatch_files[@]} )); then
    break
  fi
  echo "输入无效，请重新输入"
done

selected_file="${dispatch_files[$((choice - 1))]}"
selected_name="${dispatch_names[$((choice - 1))]}"

echo "已选择: $selected_name ($selected_file)"

last_params_file="./.action_runner_last_params.json"

inputs_json="$(ruby -ryaml -rjson -e '
  file = ARGV[0]
  data = YAML.load_file(file) || {}
  on_node = data["on"] || data[true] || {}
  wd = on_node["workflow_dispatch"]
  inputs = wd.is_a?(Hash) ? (wd["inputs"] || {}) : {}

  arr = inputs.map do |key, value|
    node = value.is_a?(Hash) ? value : {}
    {
      "name" => key.to_s,
      "description" => (node["description"] || "").to_s,
      "required" => !!node["required"],
      "default" => node.key?("default") ? node["default"].to_s : nil
    }
  end

  puts JSON.generate(arr)
' "$selected_file")"

declare -a input_args=()
used_inputs_json='{}'
use_last_params="false"

if [[ -f "$last_params_file" ]] && jq -e . "$last_params_file" >/dev/null 2>&1; then
  if jq -e --arg wf "$selected_file" '.workflows[$wf].inputs? != null' "$last_params_file" >/dev/null 2>&1; then
    echo "检测到上一次参数（来自 ${last_params_file}）:"
    jq -r --arg wf "$selected_file" '
      .workflows[$wf] as $w
      | "上次分支: \($w.branch // "unknown") | 上次时间: \($w.updated_at // "unknown")",
        (($w.inputs | to_entries[]?) | "- \(.key)=\(.value)")
    ' "$last_params_file"
    read -r -p "是否使用上一次参数? [y/N]: " reuse_ans
    if [[ "$reuse_ans" =~ ^[Yy]$ ]]; then
      use_last_params="true"
    fi
  fi
fi

if [[ "$(jq 'length' <<<"$inputs_json")" -gt 0 ]]; then
  echo "该 Action 需要/支持以下参数:"
  mapfile -t input_items < <(jq -c '.[]' <<<"$inputs_json")
  for input_item in "${input_items[@]}"; do
    name="$(jq -r '.name' <<<"$input_item")"
    desc="$(jq -r '.description' <<<"$input_item")"
    required="$(jq -r '.required' <<<"$input_item")"
    default="$(jq -r '.default // empty' <<<"$input_item")"

    [[ -n "$desc" ]] && echo "- $name: $desc"

    value=""
    if [[ "$use_last_params" == "true" ]]; then
      value="$(jq -r --arg wf "$selected_file" --arg key "$name" '.workflows[$wf].inputs[$key] // empty' "$last_params_file" 2>/dev/null || true)"
      if [[ -n "$value" ]]; then
        echo "  使用上一次参数: $name=$value"
      fi
    fi

    while true; do
      if [[ -n "$value" ]]; then
        break
      fi

      if [[ -n "$default" ]]; then
        read -r -p "请输入 $name (默认: $default): " value
        value="${value:-$default}"
      else
        read -r -p "请输入 $name: " value
      fi

      if [[ "$required" == "true" && -z "$value" ]]; then
        echo "参数 $name 是必填，请重新输入"
        continue
      fi
      break
    done

    if [[ -n "$value" ]]; then
      input_args+=("-f" "$name=$value")
      used_inputs_json="$(jq -c --arg k "$name" --arg v "$value" '. + {($k): $v}' <<<"$used_inputs_json")"
    fi
  done
fi

timestamp_utc="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
if [[ -f "$last_params_file" ]] && jq -e . "$last_params_file" >/dev/null 2>&1; then
  existing_params_json="$(cat "$last_params_file")"
else
  existing_params_json='{}'
fi

updated_params_json="$(jq -c \
  --arg wf "$selected_file" \
  --arg branch "$branch" \
  --arg ts "$timestamp_utc" \
  --argjson inputs "$used_inputs_json" \
  '
    .workflows = (.workflows // {}) |
    .workflows[$wf] = {
      "branch": $branch,
      "updated_at": $ts,
      "inputs": $inputs
    }
  ' <<<"$existing_params_json")"

printf '%s\n' "$updated_params_json" > "$last_params_file"
echo "已保存本次参数到: $last_params_file"

echo "正在触发 Action..."
start_epoch="$(date +%s)"

gh workflow run "$selected_file" --ref "$branch" "${input_args[@]}"

run_id=""
for _ in {1..30}; do
  run_id="$(gh run list \
    --workflow "$selected_file" \
    --branch "$branch" \
    --event workflow_dispatch \
    --limit 20 \
    --json databaseId,createdAt \
    | jq -r --argjson start "$start_epoch" '
      map(select((.createdAt | fromdateiso8601) >= ($start - 10)))
      | sort_by(.createdAt)
      | reverse
      | .[0].databaseId // empty
    ')"

  if [[ -n "$run_id" ]]; then
    break
  fi
  sleep 2
done

if [[ -z "$run_id" ]]; then
  echo "已触发，但暂时未定位到本次 run，请稍后到 GitHub Actions 页面查看"
  exit 1
fi

run_url="https://github.com/$repo/actions/runs/$run_id"
echo "Run ID: $run_id"
echo "页面: $run_url"
echo "开始实时跟踪状态..."

if gh run watch "$run_id" --interval 5 --exit-status; then
  echo "Action 执行成功，正在打开结果页面..."
  open -a "Google Chrome" "$run_url" >/dev/null 2>&1 || open "$run_url"
  exit 0
fi

echo "Action 执行失败。"
echo "失败步骤:"
gh run view "$run_id" --json jobs \
  | jq -r '
      .jobs[]
      | select(.conclusion == "failure")
      | "- Job: \(.name) | 失败步骤: " +
        (((.steps // []) | map(select(.conclusion == "failure") | .name)) | join(", "))
    '

echo ""
echo "失败日志（截取前 120 行）:"
gh run view "$run_id" --log-failed 2>/dev/null | sed -n "1,120p" || true

exit 1
