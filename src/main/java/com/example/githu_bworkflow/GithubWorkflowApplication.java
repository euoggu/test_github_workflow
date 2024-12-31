package com.example.githu_bworkflow;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

@SpringBootApplication
public class GithubWorkflowApplication {

    public static void main(String[] args) {
        try {
            // 获取桌面路径
            String desktopPath = System.getProperty("user.home") + "\\Desktop";
            
            // 获取系统用户名
            String username = System.getProperty("user.name");
            
            // 创建文件
            File file = new File(desktopPath + "\\mk42.txt");
            
            // 写入用户名
            try (FileWriter writer = new FileWriter(file)) {
                writer.write("当前系统用户名: " + username);
            }
            
            System.out.println("文件已创建在: " + file.getAbsolutePath());
            
        } catch (IOException e) {
            System.err.println("创建文件时发生错误: " + e.getMessage());
        }

        // SpringApplication.run(GithubWorkflowApplication.class, args);
    }
}
