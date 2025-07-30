find lib -name "*.ex" | sort | while read file; do
  echo "// $file" >> content_file.txt
  cat "$file" >> content_file.txt
  echo -e "\n" >> content_file.txt
done