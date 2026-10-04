import os
import sys
import base64
import subprocess
import shutil
from PIL import Image

WORKSPACE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PUB_DIR = os.path.join(WORKSPACE, "publishing")
SRC_DIR = os.path.join(PUB_DIR, "source_assets")
OUT_MAC = os.path.join(PUB_DIR, "screenshots", "mac")
MAC_FASTLANE_DIR = os.path.join(WORKSPACE, "ios", "fastlane", "screenshots_mac", "en-US")

os.makedirs(OUT_MAC, exist_ok=True)
os.makedirs(MAC_FASTLANE_DIR, exist_ok=True)

def to_base64(path):
    with open(path, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode("utf-8")

slides = [
    {
        "index": 1,
        "id": "01_hero_all_format",
        "eyebrow": "ALL-FORMAT PLAYBACK ENGINE",
        "headline_line1": "Play everything.",
        "headline_line2": "In pure <span class=\"lit\">HDR clarity.</span>",
        "subline": "Hardware-accelerated playback for local media, playlists, and live streams.",
        "screen_img": to_base64(os.path.join(SRC_DIR, "mac_01_hero.png")),
        "chip_pos": "right",
        "chip_status": "HARDWARE ACCELERATED",
        "chip_title": "All-Format Engine",
        "chip_meta": "HDR10 · HLS · DASH · LOCAL FILES"
    },
    {
        "index": 2,
        "id": "02_color_mastering",
        "eyebrow": "PRO MASTERING CONTROLS",
        "headline_line1": "Every frame,",
        "headline_line2": "color <span class=\"lit\">graded live.</span>",
        "subline": "Live hardware brightness, contrast, saturation, gamma, and hue adjustments.",
        "screen_img": to_base64(os.path.join(SRC_DIR, "mac_02_color.png")),
        "chip_pos": "left",
        "chip_status": "FRAME-BY-FRAME DSP",
        "chip_title": "Hardware Color Grade",
        "chip_meta": "GAMMA · CONTRAST · HUE · SATURATION"
    },
    {
        "index": 3,
        "id": "03_tools_settings",
        "eyebrow": "PRO PLAYBACK TOOLKIT",
        "headline_line1": "Smart playback.",
        "headline_line2": "Tuned to <span class=\"lit\">your rhythm.</span>",
        "subline": "Integrated stream diagnostics, media inspector, and storage tools.",
        "screen_img": to_base64(os.path.join(SRC_DIR, "mac_03_settings.png")),
        "chip_pos": "right",
        "chip_status": "ALL-IN-ONE TOOLKIT",
        "chip_title": "Pro Media Suite",
        "chip_meta": "STREAM CHECK · MEDIA INFO · SPEED TEST"
    },
    {
        "index": 4,
        "id": "04_speed_diagnostics",
        "eyebrow": "STREAM INTELLIGENCE",
        "headline_line1": "Zero buffer.",
        "headline_line2": "Tested in <span class=\"lit\">real time.</span>",
        "subline": "Integrated speed test, latency diagnostics, and stream quality readiness.",
        "screen_img": to_base64(os.path.join(SRC_DIR, "mac_04_speed_test.png")),
        "chip_pos": "left",
        "chip_status": "NETWORK VERIFIED",
        "chip_title": "Stream Speed Test",
        "chip_meta": "151 MBPS · 24 MS PING · STREAM READY"
    },
    {
        "index": 5,
        "id": "05_privacy_storage",
        "eyebrow": "LOCAL STORAGE & PRIVACY",
        "headline_line1": "Your media.",
        "headline_line2": "Zero <span class=\"lit\">tracking.</span>",
        "subline": "Complete on-device privacy, direct local file playback, and cache management.",
        "screen_img": to_base64(os.path.join(SRC_DIR, "mac_05_storage.png")),
        "chip_pos": "right",
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
  }}
  body {{
    width: 2880px;
    height: 1800px;
    background: radial-gradient(circle at 50% -10%, #1a1e30 0%, #0c0e17 50%, #06070a 100%);
    font-family: 'Figtree', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    color: #fff;
    overflow: hidden;
    position: relative;
    display: flex;
    flex-direction: column;
    align-items: center;
  }}

  /* Ambient Glow Behind Mac Window */
  .ambient-glow {{
    position: absolute;
    top: 360px;
    left: 50%;
    transform: translateX(-50%);
    width: 1800px;
    height: 700px;
    background: radial-gradient(ellipse at center, rgba(94, 96, 238, 0.18) 0%, rgba(94, 96, 238, 0.05) 50%, transparent 75%);
    filter: blur(80px);
    pointer-events: none;
    z-index: 1;
  }}

  /* Header Section */
  .header-zone {{
    width: 2400px;
    margin-top: 80px;
    text-align: center;
    display: flex;
    flex-direction: column;
    align-items: center;
    z-index: 10;
  }}

  .eyebrow {{
    font-size: 22px;
    font-weight: 700;
    letter-spacing: 0.16em;
    color: #A5B4FC;
    text-transform: uppercase;
    margin-bottom: 20px;
  }}

  .headline {{
    font-size: 68px;
    line-height: 1.14;
    font-weight: 800;
    letter-spacing: -1.5px;
    color: #FFFFFF;
    margin-bottom: 16px;
  }}

  .headline .lit {{
    background: linear-gradient(135deg, #A5B4FC 0%, #818CF8 50%, #C084FC 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    display: inline;
  }}

  .subline {{
    font-size: 26px;
    font-weight: 500;
    color: #94A3B8;
    letter-spacing: -0.2px;
    max-width: 1600px;
    line-height: 1.35;
  }}

  /* Window Mockup Area */
  .window-container {{
    position: relative;
    width: 2280px;
    margin-top: 48px;
    z-index: 5;
  }}

  .mac-window {{
    width: 100%;
    background: #07080C;
    border-radius: 20px;
    border: 1.5px solid rgba(255, 255, 255, 0.14);
    box-shadow: 
      0 45px 120px -20px rgba(0, 0, 0, 0.85),
      0 20px 50px -10px rgba(0, 0, 0, 0.65),
      0 0 0 1px rgba(255, 255, 255, 0.05);
    overflow: hidden;
    display: flex;
    flex-direction: column;
  }}

  /* macOS Window Title Bar */
  .title-bar {{
    height: 48px;
    background: #10121A;
    border-bottom: 1px solid rgba(255, 255, 255, 0.08);
    display: flex;
    align-items: center;
    padding: 0 20px;
    position: relative;
  }}

  .traffic-lights {{
    display: flex;
    align-items: center;
    gap: 10px;
  }}

  .light {{
    width: 14px;
    height: 14px;
    border-radius: 50%;
  }}

  .light.close {{ background: #FF5F56; border: 1px solid #E0443E; }}
  .light.min {{ background: #FFBD2E; border: 1px solid #DEA123; }}
  .light.max {{ background: #27C93F; border: 1px solid #1AAB29; }}

  /* Screenshot Content */
  .window-screen {{
    width: 100%;
    height: 1140px;
    position: relative;
    overflow: hidden;
  }}

  .window-screen img {{
    width: 100%;
    height: 100%;
    object-fit: cover;
    object-position: top center;
    display: block;
  }}

  /* Floating Glassmorphic Feature Badge */
  .chip {{
    position: absolute;
    bottom: -24px;
    {chip_horizontal}
    background: rgba(13, 16, 26, 0.90);
    backdrop-filter: blur(28px);
    -webkit-backdrop-filter: blur(28px);
    border: 1.5px solid rgba(255, 255, 255, 0.18);
    border-radius: 20px;
    padding: 20px 28px;
    display: flex;
    flex-direction: column;
    gap: 6px;
    box-shadow: 
      0 24px 60px rgba(0, 0, 0, 0.75),
      0 4px 16px rgba(94, 96, 238, 0.25);
    z-index: 20;
    min-width: 440px;
  }}

  .chip-status {{
    font-size: 14px;
    font-weight: 800;
    letter-spacing: 1.8px;
    color: #818CF8;
    text-transform: uppercase;
    display: flex;
    align-items: center;
    gap: 8px;
  }}

  .chip-status::before {{
    content: '';
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: #818CF8;
    box-shadow: 0 0 8px #818CF8;
  }}

  .chip-title {{
    font-size: 26px;
    font-weight: 800;
    color: #FFFFFF;
    letter-spacing: -0.4px;
  }}

  .chip-meta {{
    font-size: 15px;
    font-weight: 600;
    letter-spacing: 1.2px;
    color: #94A3B8;
    text-transform: uppercase;
  }}
</style>
</head>
<body>
  <div class="ambient-glow"></div>

  <div class="header-zone">
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

  <div class="window-container">
    <div class="mac-window">
      <div class="title-bar">
        <div class="traffic-lights">
          <div class="light close"></div>
          <div class="light min"></div>
          <div class="light max"></div>
        </div>
      </div>
      <div class="window-screen">
        <img src="{screen_img}" alt="Screenshot">
      </div>
    </div>

    <div class="chip">
      <div class="chip-status">{chip_status}</div>
      <div class="chip-title">{chip_title}</div>
      <div class="chip-meta">{chip_meta}</div>
    </div>
  </div>
</body>
</html>
"""

def main():
    print("Generating Mac App Store screenshots (2880x1800)...")
    for slide in slides:
        chip_horizontal = "right: 40px;" if slide["chip_pos"] == "right" else "left: 40px;"
        
        html_content = HTML_TEMPLATE.format(
            eyebrow=slide["eyebrow"],
            headline_line1=slide["headline_line1"],
            headline_line2=slide["headline_line2"],
            subline=slide["subline"],
            screen_img=slide["screen_img"],
            chip_horizontal=chip_horizontal,
            chip_status=slide["chip_status"],
            chip_title=slide["chip_title"],
            chip_meta=slide["chip_meta"]
        )
        
        html_path = f"/tmp/{slide['id']}.html"
        with open(html_path, "w") as f:
            f.write(html_content)
            
        out_png_mac = os.path.join(OUT_MAC, f"{slide['id']}.png")
        
        cmd = [
            "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
            "--headless",
            "--disable-gpu",
            "--hide-scrollbars",
            "--window-size=2880,1800",
            "--virtual-time-budget=3500",
            f"--screenshot={out_png_mac}",
            html_path
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        # Fastlane delivery filename: {index}_Mac_2880x1800_{id}.png
        fastlane_mac_png = os.path.join(MAC_FASTLANE_DIR, f"{slide['index']}_Mac_2880x1800_{slide['id']}.png")
        shutil.copy2(out_png_mac, fastlane_mac_png)
        
        im = Image.open(out_png_mac)
        print(f"Generated Mac #{slide['index']} {slide['id']}: {im.size} -> {fastlane_mac_png}")

    print("\nAll 5 Mac screenshots generated successfully!")

if __name__ == "__main__":
    main()
