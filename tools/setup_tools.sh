
# GearUI工具安装脚本

echo "开始创建Xcode模版..."
mkdir -p ~/Library/Developer/Xcode/Templates/Files\ Templates/GearUI
cp -R ./templates/GearUI\ View\ Controller.xctemplate/ ~/Library/Developer/Xcode/Templates/Files\ Templates/GearUI/GearUI\ View\ Controller.xctemplate/
cp -R ./templates/GearUI\ Layout\ View.xctemplate/ ~/Library/Developer/Xcode/Templates/Files\ Templates/GearUI/GearUI\ Layout\ View.xctemplate/
echo "Xcode模版创建完成"

echo "开始创建Code Snippet"
mkdir -p ~/Library/Developer/Xcode/UserData/CodeSnippets
cp -f ./templates/CodeSnippets/* ~/Library/Developer/Xcode/UserData/CodeSnippets
echo "Code Snippet创建完成"
