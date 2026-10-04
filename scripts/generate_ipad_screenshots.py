import os
import sys
import base64
import subprocess
import shutil
from PIL import Image

WORKSPACE = os.path.dirname(os.path.abspath(__file__))
PUB_DIR = os.path.join(WORKSPACE, "publishing")
SRC_DIR = os.path.join(PUB_DIR, "source_assets")
OUT_IPAD = os.path.join(PUB_DIR, "screenshots", "ipad_12_9")
IOS_FASTLANE_DIR = os.path.join(WORKSPACE, "ios", "fastlane", "screenshots", "en-US")
ANDROID_FASTLANE_10INCH = os.path.join(WORKSPACE, "android", "fastlane", "metadata", "android", "en-US", "images", "tenInchScreenshots")

os.makedirs(OUT_IPAD, exist_ok=True)
os.makedirs(IOS_FASTLANE_DIR, exist_ok=True)
os.makedirs(ANDROID_FASTLANE_10INCH, exist_ok=True)

def to_base64(path):
    with open(path, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode("utf-8")

mockup_ipad_b64 = to_base64(os.path.join(SRC_DIR, "mockup-ipad.png"))

slides = [
    {
        "index": 1,
        "id": "01_hero_4k",
        "eyebrow": "ULTRA-HD PLAYBACK ENGINE",
        "headline_line1": "Play everything.",
        "headline_line2": "In pure <span class=\"lit\">HDR clarity.</span>",
        "subline": "Hardware-accelerated playback for local media and live streams.",
        "screen_img": to_base64(os.path.join(SRC_DIR, "ipad_01_home.png")),
        "chip_pos": "left",
        "chip_vertical": "bottom: 20%;",
        "chip_status": "HARDWARE ACCELERATED",
        "chip_title": "Ultra-HD HEVC",
        "chip_meta": "HDR10 · HLS · DASH · LOCAL FILES"
    },
    {
        "index": 2,
        "id": "02_equalizer_bass",
        "eyebrow": "PRO PLAYBACK CONTROLS",
        "headline_line1": "Smart playback.",
        "headline_line2": "Tuned to <span class=\"lit\">your rhythm.</span>",
        "subline": "Custom seek gestures, stream inspection, and comprehensive media tools.",
        "screen_img": to_base64(os.path.join(SRC_DIR, "ipad_02_settings.png")),
        "chip_pos": "right",
        "chip_vertical": "bottom: 20%;",
        "chip_status": "PLAYER TOOLKIT",
        "chip_title": "Custom Seek Controls",
        "chip_meta": "5S–30S SEEK · STREAM CHECK · MEDIA INFO"
    },
    {
        "index": 3,
        "id": "03_speed_diagnostics",
        "eyebrow": "STREAM INTELLIGENCE",
        "headline_line1": "Zero buffer.",
        "headline_line2": "Tested in <span class=\"lit\">real time.</span>",
        "subline": "Integrated speed test, ping diagnostics, and stream readiness.",
        "screen_img": to_base64(os.path.join(SRC_DIR, "ipad_03_speed_test.png")),
        "chip_pos": "right",
        "chip_vertical": "bottom: 20%;",
        "chip_status": "NETWORK VERIFIED",
        "chip_title": "Stream Speed Test",
        "chip_meta": "PING · JITTER · STREAM READY"
    },
    {
        "index": 4,
        "id": "04_color_mastering",
        "eyebrow": "PRO MASTERING CONTROLS",
        "headline_line1": "Every frame,",
        "headline_line2": "color <span class=\"lit\">graded live.</span>",
        "subline": "Live brightness, contrast, saturation, gamma, and hue adjustments.",
        "screen_img": to_base64(os.path.join(SRC_DIR, "ipad_04_color_grade.png")),
        "chip_pos": "left",
        "chip_vertical": "bottom: 20%;",
        "chip_status": "FRAME-BY-FRAME DSP",
        "chip_title": "Hardware Color Grade",
        "chip_meta": "GAMMA · CONTRAST · HUE · SATURATION"
    },
    {
        "index": 5,
        "id": "05_privacy_storage",
        "eyebrow": "LOCAL STORAGE & PRIVACY",
        "headline_line1": "Your media.",
        "headline_line2": "Zero <span class=\"lit\">tracking.</span>",
        "subline": "Complete on-device privacy, local file sandbox, and cache management.",
        "screen_img": to_base64(os.path.join(SRC_DIR, "ipad_05_storage.png")),
        "chip_pos": "right",
        "chip_vertical": "bottom: 20%;",
        "chip_status": "ON-DEVICE PRIVACY",
        "chip_title": "Zero Data Collected",
        "chip_meta": "LOCAL SANDBOX · DIRECT FILES"
    }
]

HTML_TEMPLATE = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Figtree:ital,wght@0,300..900;1,300..900&display=block" rel="stylesheet">
<style>
  * {{
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    -webkit-font-smoothing: antialiased;
  }}

  body {{
    width: 2048px;
    height: 2732px;
    overflow: hidden;
    position: relative;
    background: #07080B;
    color: #F4F5F8;
    font-family: 'Figtree', -apple-system, sans-serif;
  }}

  /* Base 4-stop dark background */
  .base {{
    position: absolute;
    inset: 0;
    background: linear-gradient(180deg, #0B0D13 0%, #08090D 38%, #07080B 70%, #050608 100%);
    pointer-events: none;
  }}

  /* Engineering dot grid with mask cut under text */
  .grid {{
    position: absolute;
    inset: 0;
    background-image: radial-gradient(circle at 2px 2px, rgba(255, 255, 255, 0.12) 1.5px, transparent 2.2px);
    background-size: 56px 56px;
    background-position: 28px 14px;
    -webkit-mask: radial-gradient(ellipse 70% 45% at 50% 30%, #000 10%, rgba(0,0,0,0.35) 55%, transparent 80%),
                 linear-gradient(180deg, #000 0, #000 240px, transparent 270px, transparent 720px, #000 760px);
    -webkit-mask-composite: source-in;
    mask-composite: intersect;
    pointer-events: none;
  }}

  /* Top Horizon light line & bloom */
  .horizon {{
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 2px;
    background: linear-gradient(90deg, transparent 8%, rgba(185,182,255,0.35) 30%, rgba(230,228,255,0.95) 50%, rgba(185,182,255,0.35) 70%, transparent 92%);
    pointer-events: none;
  }}

  .horizon-bloom {{
    position: absolute;
    left: 50%;
    transform: translateX(-50%);
    top: -300px;
    width: 2400px;
    height: 600px;
    filter: blur(45px);
    background: radial-gradient(ellipse 34% 50% at 50% 50%, rgba(130,124,255,0.55), rgba(130,124,255,0.12) 55%, transparent 75%);
    pointer-events: none;
  }}

  /* Indigo-violet light beam from top */
  .beam-wide {{
    position: absolute;
    inset: -300px;
    filter: blur(55px);
    background: conic-gradient(from 160deg at 1400px 80px, transparent 0deg,
      rgba(110,106,255,0.10) 9deg, rgba(150,120,255,0.22) 20deg, rgba(110,106,255,0.10) 31deg, transparent 40deg);
    -webkit-mask: linear-gradient(180deg, rgba(0,0,0,0.55) 0%, #000 30%, #000 55%, transparent 88%);
    mix-blend-mode: screen;
    pointer-events: none;
  }}

  .beam-core {{
    position: absolute;
    inset: -300px;
    filter: blur(20px);
    background: conic-gradient(from 173.5deg at 1400px 80px, transparent 0deg,
      rgba(150,146,255,0.20) 4deg, rgba(196,188,255,0.35) 6.5deg, rgba(150,146,255,0.20) 9deg, transparent 13deg);
    -webkit-mask: linear-gradient(180deg, rgba(0,0,0,0.28) 0px, rgba(0,0,0,0.34) 860px, #000 1010px, #000 1500px, transparent 2300px);
    mix-blend-mode: screen;
    pointer-events: none;
  }}

  .vignette {{
    position: absolute;
    inset: 0;
    background: radial-gradient(ellipse 120% 80% at 50% 38%, transparent 55%, rgba(0,0,0,0.55) 100%);
    pointer-events: none;
  }}

  /* Header Container */
  .header-container {{
    position: absolute;
    top: 0;
    left: 0;
    width: 2048px;
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
    padding-top: 130px;
    z-index: 10;
  }}

  /* Eyebrow - Figtree only, NO double slashes (//) */
  .eyebrow {{
    font-family: 'Figtree', sans-serif;
    font-size: 30px;
    font-weight: 700;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: #A7ACBA;
    display: flex;
    align-items: center;
  }}

  /* Headline - Figtree 800 with vertical text gradient */
  .headline {{
    font-family: 'Figtree', sans-serif;
    font-weight: 800;
    font-size: 148px;
    line-height: 1.04;
    letter-spacing: -0.035em;
    margin-top: 24px;
    padding-bottom: 0.08em;
    background: linear-gradient(180deg, #FFFFFF 0%, #FFFFFF 38%, #B9BDC9 100%);
    -webkit-background-clip: text;
    background-clip: text;
    color: transparent;
    max-width: 1800px;
  }}

  .headline .lit {{
    background: linear-gradient(180deg, #E2E0FF 0%, #C2BFFF 55%, #B3AFFF 100%);
    -webkit-background-clip: text;
    background-clip: text;
    color: transparent;
  }}

  .subline {{
    font-family: 'Figtree', sans-serif;
    font-size: 44px;
    font-weight: 400;
    line-height: 1.34;
    letter-spacing: -0.01em;
    color: #B4B9C6;
    margin-top: 20px;
    max-width: 1500px;
  }}

  /* iPad Stage */
  .ipad-stage {{
    position: absolute;
    left: 338px;
    top: 730px;
    width: 1372px;
    height: 1900px;
    z-index: 20;
  }}

  /* Bezel Halo & Bloom */
  .ipad-halo {{
    position: absolute;
    inset: -6px;
    border-radius: 46px;
    filter: blur(12px);
    background: linear-gradient(180deg, rgba(200,196,255,0.95) 0%, rgba(160,156,255,0.55) 6%, rgba(143,140,255,0) 26%);
    pointer-events: none;
    z-index: 1;
  }}

  .ipad-bloom {{
    position: absolute;
    left: 10%;
    right: 10%;
    top: -120px;
    height: 480px;
    filter: blur(75px);
    background: radial-gradient(ellipse at 50% 60%, rgba(143,140,255,0.55), transparent 70%);
    pointer-events: none;
    z-index: 2;
  }}

  .ipad-wrapper {{
    position: relative;
    width: 100%;
    height: 100%;
    filter: drop-shadow(0 60px 70px rgba(0,0,0,0.85)) drop-shadow(0 14px 28px rgba(0,0,0,0.6));
    z-index: 5;
  }}

  .mockup-img {{
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    display: block;
    z-index: 20;
    pointer-events: none;
  }}

  /* Inner Screen */
  .screen-frame {{
    position: absolute;
    left: 5.0%;
    top: 3.7%;
    width: 90.0%;
    height: 92.6%;
    border-radius: 36px;
    overflow: hidden;
    background: #000;
    z-index: 10;
  }}

  .screen-img {{
    width: 100%;
    height: 100%;
    object-fit: cover;
    object-position: top;
    display: block;
  }}

  /* Floor Line & Floor Reflection */
  .floor-line {{
    position: absolute;
    top: 2630px;
    left: 0;
    width: 100%;
    height: 2px;
    background: linear-gradient(90deg, transparent 4%, rgba(185,182,255,0.45) 30%, rgba(210,208,255,0.7) 50%, rgba(185,182,255,0.45) 70%, transparent 96%);
    z-index: 5;
  }}

  .floor-glow {{
    position: absolute;
    left: 200px;
    top: 2540px;
    width: 1648px;
    height: 220px;
    filter: blur(35px);
    background: radial-gradient(ellipse at 50% 50%, rgba(124,120,255,0.35), transparent 70%);
    pointer-events: none;
    z-index: 4;
  }}

  /* Reflection under iPad */
  .reflection {{
    position: absolute;
    left: 338px;
    top: 2632px;
    width: 1372px;
    height: 260px;
    transform: scaleY(-1);
    opacity: 0.18;
    -webkit-mask: linear-gradient(0deg, #000 0%, transparent 45%);
    mask: linear-gradient(0deg, #000 0%, transparent 45%);
    overflow: hidden;
    pointer-events: none;
    z-index: 6;
  }}

  .reflection img {{
    width: 100%;
    height: 1900px;
    display: block;
  }}

  /* Dark Glass Tech Spec Card */
  .tech-chip {{
    position: absolute;
    width: 580px;
    border-radius: 24px;
    background: linear-gradient(180deg, rgba(22,25,35,0.92), rgba(13,15,22,0.88));
    backdrop-filter: blur(32px) saturate(140%);
    -webkit-backdrop-filter: blur(32px) saturate(140%);
    box-shadow: inset 0 1px 0 rgba(255,255,255,0.14),
                0 0 0 1px rgba(0,0,0,0.65),
                0 25px 50px -10px rgba(0,0,0,0.85),
                0 0 35px -8px rgba(124,120,255,0.25);
    padding: 24px 32px;
    z-index: 35;
    border: 1px solid rgba(206,202,255,0.24);
  }}

  .tech-chip.left {{
    left: -70px;
  }}

  .tech-chip.right {{
    right: -70px;
  }}

  .chip-status {{
    font-family: 'Figtree', sans-serif;
    font-size: 20px;
    font-weight: 700;
    color: #B3AFFF;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 8px;
  }}

  .chip-status .dot {{
    width: 10px;
    height: 10px;
    border-radius: 50%;
    background: #8F8CFF;
    box-shadow: 0 0 12px #8F8CFF;
  }}

  .chip-title {{
    font-family: 'Figtree', sans-serif;
    font-size: 34px;
    font-weight: 700;
    letter-spacing: -0.02em;
    color: #F4F5F8;
    line-height: 1.15;
    margin-bottom: 8px;
  }}

  .chip-meta {{
    font-family: 'Figtree', sans-serif;
    font-size: 20px;
    font-weight: 500;
    color: #8B91A0;
    letter-spacing: 0.04em;
  }}
</style>
</head>
<body>
  <!-- Background Stack -->
  <div class="base"></div>
  <div class="grid"></div>
  <div class="horizon"></div>
  <div class="horizon-bloom"></div>
  <div class="beam-wide"></div>
  <div class="beam-core"></div>
  <div class="vignette"></div>

  <!-- Header -->
  <div class="header-container">
    <div class="eyebrow">
      {eyebrow}
    </div>
    <div class="headline">
      {headline_line1}<br>{headline_line2}
    </div>
    <div class="subline">
      {subline}
    </div>
  </div>

  <!-- iPad Stage -->
  <div class="ipad-stage">
    <div class="ipad-halo"></div>
    <div class="ipad-bloom"></div>
    <div class="ipad-wrapper">
      <div class="screen-frame">
        <img class="screen-img" src="{screen_img}">
      </div>
      <img class="mockup-img" src="{mockup_ipad_b64}">
    </div>

    <!-- Tech Spec Glass Card -->
    <div class="tech-chip {chip_pos}" style="{chip_vertical}">
      <div class="chip-status">
        <span class="dot"></span> {chip_status}
      </div>
      <div class="chip-title">{chip_title}</div>
      <div class="chip-meta">{chip_meta}</div>
    </div>
  </div>

  <!-- Floor line & Reflection -->
  <div class="floor-line"></div>
  <div class="floor-glow"></div>
  <div class="reflection">
    <img src="{mockup_ipad_b64}">
  </div>
</body>
</html>
"""

def generate_ipad_screenshots(filter_id=None):
    chrome_bin = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    
    for slide in slides:
        if filter_id and filter_id not in slide["id"].lower():
            continue
            
        print(f"Rendering iPad slide {slide['index']}: {slide['id']}...")
        html_content = HTML_TEMPLATE.format(
            eyebrow=slide["eyebrow"],
            headline_line1=slide["headline_line1"],
            headline_line2=slide["headline_line2"],
            subline=slide["subline"],
            screen_img=slide["screen_img"],
            mockup_ipad_b64=mockup_ipad_b64,
            chip_pos=slide["chip_pos"],
            chip_vertical=slide["chip_vertical"],
            chip_status=slide["chip_status"],
            chip_title=slide["chip_title"],
            chip_meta=slide["chip_meta"]
        )
        
        html_path = f"/tmp/ipad_{slide['id']}.html"
        with open(html_path, "w") as f:
            f.write(html_content)
            
        out_png = os.path.join(OUT_IPAD, f"{slide['id']}.png")
        
        cmd = [
            chrome_bin,
            "--headless",
            "--disable-gpu",
            "--hide-scrollbars",
            "--window-size=2048,2732",
            "--virtual-time-budget=3500",
            f"--screenshot={out_png}",
            html_path
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        # Verify output size
        im = Image.open(out_png)
        print(f"  Generated {out_png} -> {im.size} ({os.path.getsize(out_png):,} bytes)")
        
        # Copy to iOS Fastlane directory with standard naming
        ios_dest_name = f"{slide['index']}_iPad_12.9_{slide['id']}.png"
        ios_dest = os.path.join(IOS_FASTLANE_DIR, ios_dest_name)
        shutil.copyfile(out_png, ios_dest)
        print(f"  -> Copied to iOS Fastlane: {ios_dest_name}")

        # Copy to Android Fastlane 10-inch screenshots directory
        android_dest_name = f"{slide['index']}.png"
        android_dest = os.path.join(ANDROID_FASTLANE_10INCH, android_dest_name)
        shutil.copyfile(out_png, android_dest)
        print(f"  -> Copied to Android 10-inch Fastlane: {android_dest_name}")

    print("\nAll iPad screenshots successfully generated and synced to Fastlane directories!")

if __name__ == "__main__":
    arg = sys.argv[1].lower() if len(sys.argv) > 1 else None
    generate_ipad_screenshots(arg)
