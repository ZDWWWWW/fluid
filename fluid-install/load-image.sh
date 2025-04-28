#!/bin/bash
# 加载镜像到指定仓库
# load-image.sh -d images -r "registry.cn-hangzhou.aliyuncs.com/codev"
# 加载镜像到本地docker
# load-image.sh -d images --daemon
set -e

# 设置默认目录和新的仓库
load_dir="images"
new_registry=""
daemon_mode=false

# 检查命令行参数是否设置了自定义目录、新的仓库或daemon模式
while getopts "d:r:-:" opt; do
  case $opt in
    d) load_dir="$OPTARG" ;;        # 设置加载镜像的自定义目录
    r) new_registry="$OPTARG" ;;    # 设置新的仓库地址
    -)
      case $OPTARG in
        daemon) daemon_mode=true ;;  # 启用daemon模式
        *) echo "Invalid option --$OPTARG" >&2; exit 1 ;;
      esac
      ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done

# 确保加载目录存在
if [ ! -d "$load_dir" ]; then
  echo "Directory $load_dir does not exist."
  exit 1
fi

# 定义转换函数，与 save-image.sh 的逻辑一致
convert_to_filename() {
    echo "$1" | sed 's/\//#/g' | sed 's/:/+/g'
}

convert_to_image_name() {
    echo "$1" | sed 's/#/\//g' | sed 's/+/:/g'
}

# 遍历加载目录下的所有 tar 文件
for tar_file in "$load_dir"/*.tar; do
    # 检查是否存在 tar 文件
    if [ ! -f "$tar_file" ]; then
        echo "No tar files found in $load_dir"
        exit 1
    fi

    # 从文件名获取镜像名称
    base_name=$(basename "$tar_file" .tar)
    image_name=$(convert_to_image_name "$base_name")
    image_name_tag=${image_name#*/*/}
    
    # 形成新的镜像名称，添加新的仓库前缀
    if [ -n "$new_registry" ]; then
        new_image="$new_registry/$image_name_tag"
    else
        new_image="$image_name"
    fi

    # 使用 docker load 将镜像加载到本地
    echo "Loading image from $tar_file"
    echo "docker load -i $tar_file"
    docker load -i "$tar_file"
    echo "docker tag $image_name $new_image"
    docker tag "$image_name" "$new_image"

    # 在非daemon模式下才推送镜像
    if ! $daemon_mode; then
        echo "Pushing image $new_image"
        echo "docker push $new_image"
        docker push "$new_image"
        echo "Image $new_image pushed successfully"
        docker rmi "$new_image"
    else
        echo "Image $new_image loaded and tagged locally (daemon mode enabled)"
    fi
done

echo "All images have been processed."
