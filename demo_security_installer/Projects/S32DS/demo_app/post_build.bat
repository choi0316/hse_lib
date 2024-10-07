@echo OFF
echo "Post Build Script"

echo %cd%

python ..\..\folder_shift.py

echo "Post Build Success " 
