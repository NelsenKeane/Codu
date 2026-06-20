import base64
import re

svg_path = 'assets/images/Level Map 1.svg'
with open(svg_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find the second image base64, which is on line 38
matches = re.findall(r'xlink:href="data:image/png;base64,([^"]+)"', content)
if len(matches) > 1:
    base64_data = matches[1]
    img_data = base64.b64decode(base64_data)
    with open('bottom_image.png', 'wb') as f_img:
        f_img.write(img_data)
    print("Success: Saved bottom_image.png")
else:
    print("Failure: Could not find second image base64")
