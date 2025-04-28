部署方式：
1. 导入镜像到镜像仓库

   ```sh
   ./load-image.sh -d images -r 10.10.101.138/library
   # 或者仅load到本机docker
   ./load-image.sh -d images --daemon
   ```
2. 按需修改fluid.yaml

   1. 更换名称镜像：替换 registry.aliyuncs.com/fluid 为实际的 仓库/项目
   2. 更换namespace：替换 "namespace: fluid-system" 为 "namespace: <namespace>"
3. kubectl apply -f fluid.yaml