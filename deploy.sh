# 确保脚本抛出遇到的错误
set -e

# 生成静态文件
npm run build

# 进入生成的文件夹
cd ./dist

# 如果是发布到自定义域名
echo 'gmiam.com' > CNAME

git init
git add -A
git commit -m 'deploy'


# 把下面的push命令按照你的情况修改后去掉注释
# 如果发布到 https://<USERNAME>.github.io
# git push -f git@github.com:<USERNAME>/<USERNAME>.github.io.git master
# 如果发布到 https://<USERNAME>.github.io/<REPO>
git push -f https://github.com/ygm125/blog.git master:gh-pages
