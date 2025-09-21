## GitHub Actions 环境变量配置指南 ⚙️

GitHub Actions 允许你配置两种类型的环境变量来管理工作流程 (workflows) 中的配置数据：

1. **Secrets (加密机密)**: 用于存储**敏感信息**，如密码、API 密钥、私钥等。它们在后台被加密，并且在日志中会自动隐藏，非常安全。
    
2. **Variables (普通变量)**: 用于存储**非敏感信息**，如服务器路径、用户名、编译选项等。它们以纯文本形式存储。
    

你的截图展示的是 **Secrets** 的配置，主要用于自动化部署或备份等需要登录服务器的场景。

---

## 如何配置 Secrets？

配置过程非常简单，按以下步骤操作即可。

### **第一步：进入配置页面**

1. 打开你的 GitHub 仓库主页。
    
2. 点击右上角的 **Settings** (设置) 选项卡。
    
3. 在左侧菜单栏中，找到 **Secrets and variables**，点击展开，然后选择 **Actions**。
    

### **第二步：选择 Secrets 类型并创建**

你会看到两种类型，可以根据需求选择：

- **Repository secrets (仓库机密)**:
    
    - **作用范围**: 对该仓库下**所有**的 Actions workflows 都生效。
        
    - **如何创建**: 点击 "New repository secret" 按钮。
        
- **Environment secrets (环境机密)**:
    
    - **作用范围**: 仅对**特定环境** (如 `production`, `staging`, `test`) 的 workflows 生效。这是一种更安全的做法，可以隔离不同环境的凭证。
        
    - **如何创建**: 你需要先创建一个环境 (Environment)，然后在该环境下点击 "New environment secret" 按钮。你的截图中配置的就是 `test` 环境的 Secrets。
        

### **第三步：填写信息**

1. **Name (名称)**: 给你的 Secret 起一个名字，必须大写，用下划线 `_` 分隔。例如：`SSH_PASSWORD`。在 Actions workflow 文件中会通过这个名字来引用它。
    
2. **Value / Secret (值)**: 填入你的敏感信息，例如真实的密码 `your_password_123`。
    
3. 点击 **Add secret** 按钮保存。
    

---

## 你的仓库配置示例 (`gushici-intelligent-docs`)

根据你的截图，你在一个名为 `test` 的**环境 (Environment)** 中配置了以下 Secrets。这通常用于将代码自动部署到一台测试服务器。

这些 Secrets 的含义和建议配置值如下：

- `SSH_HOSTNAME`
    
    - **用途**: 你要连接的远程服务器的 **IP 地址**或**域名**。
        
    - **示例值**: `123.45.67.89`
        
- `SSH_USERNAME`
    
    - **用途**: 登录远程服务器的**用户名**。
        
    - **示例值**: `root` 或 `ubuntu`
        
- `SSH_PASSWORD`
    
    - **用途**: 上述用户名对应的**登录密码**。
        
    - **示例值**: `YourComplexPassword@123`
        
- `SSH_PORT`
    
    - **用途**: 远程服务器的 **SSH 端口号**。
        
    - **示例值**: `22` (这是默认值)
        
- `REMOTE_WEB_DIR`
    
    - **用途**: 部署项目文件到服务器上的**目标路径** (网站根目录)。
        
    - **示例值**: `/var/www/html`
        
- `REMOTE_BACKUP_DIR`
    
    - **用途**: 在服务器上存放**备份文件**的路径。
        
    - **示例值**: `/home/backup/gushici`
        

---

## 如何在 Actions Workflow 中使用？

配置好后，你可以在 `.github/workflows/` 目录下的 YAML 文件中通过 `${{ secrets.SECRET_NAME }}` 的语法来使用它们。

这是一个简单的部署脚本示例：

YAML

```
# .github/workflows/deploy.yml
name: Deploy to Test Server

on:
  push:
    branches:
      - main # 当 main 分支有更新时触发

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: test # 指定使用 test 环境，这样才能读取到 test 环境的 Secrets

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Deploy to Server via SSH
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SSH_HOSTNAME }}
          username: ${{ secrets.SSH_USERNAME }}
          password: ${{ secrets.SSH_PASSWORD }}
          port: ${{ secrets.SSH_PORT }}
          script: |
            # 在服务器上执行的命令
            cd ${{ secrets.REMOTE_WEB_DIR }}
            echo "Deploying new version..."
            # 其他部署命令，例如 git pull, npm install 等
            echo "Deployment finished!"
```

**关键点**:

- `environment: test` 声明了此任务在 `test` 环境下运行，因此可以访问到你配置的所有 `test` 环境的 Secrets。
    
- `${{ secrets.SSH_HOSTNAME }}` 会在运行时自动被替换成你设置的真实 IP 地址，并且这个过程是安全的，不会在日志中泄露。