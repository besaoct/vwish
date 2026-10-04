import os
import sys
import base64
import subprocess
from PIL import Image

WORKSPACE = os.path.dirname(os.path.abspath(__file__))
PUB_DIR = os.path.join(WORKSPACE, "publishing")
SRC_DIR = os.path.join(PUB_DIR, "source_assets")
OUT_6_9 = os.path.join(PUB_DIR, "screenshots", "iphone_6_9")
OUT_6_5 = os.path.join(PUB_DIR, "screenshots", "iphone_6_5")

os.makedirs(OUT_6_9, exist_ok=True)
os.makedirs(OUT_6_5, exist_ok=True)

def to_base64(path):
    with open(path, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode("utf-8")

mockup_b64 = to_base64(os.path.join(SRC_DIR, "mockup.png"))

slides = [
    {
        "id": "01_hero",
        "eyebrow": "ULTRA-HD PLAYBACK ENGINE",
        "headline_line1": "Play everything.",
        "headline_line2": "In pure <span class=\"lit\">HDR clarity.</span>",
        "subline": "Hardware-accelerated playback for local media and live streams.",
        "screen_img": to_base64(os.path.join(SRC_DIR, "01_home.png")),
        "chip_pos": "left",
        "chip_vertical": "bottom: 20%;",
        "chip_status": "HARDWARE ACCELERATED",
        "chip_title": "Ultra-HD HEVC",
        "chip_meta": "HDR10 · HLS · DASH · LOCAL FILES"
    },
    {
        "id": "02_equalizer_bass",
        "eyebrow": "STUDIO AUDIO ENGINE",
        "headline_line1": "Studio sound.",
        "headline_line2": "Tuned to <span class=\"lit\">your ears.</span>",
        "subline": "10-band parametric equalizer, bass boost, and audio normalization.",
        "screen_img": to_base64(os.path.join(SRC_DIR, "02_equalizer.png")),
        "chip_pos": "right",
        "chip_vertical": "top: 20%;",
        "chip_status": "32-BIT DSP ENGINE",
        "chip_title": "10-Band Equalizer",
        "chip_meta": "+6.0 dB BASS BOOST · NORMALIZATION"
    },
    {
        "id": "03_speed_diagnostics",
        "eyebrow": "STREAM INTELLIGENCE",
        "headline_line1": "Zero buffer.",
        "headline_line2": "Tested in <span class=\"lit\">real time.</span>",
        "subline": "Integrated speed test, ping diagnostics, and stream readiness.",
        "screen_img": to_base64(os.path.join(SRC_DIR, "03_speed_test.png")),
        "chip_pos": "left",
        "chip_vertical": "bottom: 20%;",
        "chip_status": "NETWORK VERIFIED",
        "chip_title": "33.1 Mbps Download",
        "chip_meta": "69 ms PING · STREAM READY"
    },
    {
        "id": "04_color_mastering",
        "eyebrow": "PRO MASTERING CONTROLS",
        "headline_line1": "Every frame,",
        "headline_line2": "color <span class=\"lit\">graded live.</span>",
        "subline": "Live brightness, contrast, saturation, gamma, and A-B loop repeat.",
        "screen_img": to_base64(os.path.join(SRC_DIR, "04_color_grade.png")),
        "chip_pos": "right",
        "chip_vertical": "bottom: 20%;",
        "chip_status": "FRAME-BY-FRAME DSP",
        "chip_title": "Hardware Color Grade",
        "chip_meta": "GAMMA · CONTRAST · A-B REPEAT"
    },
    {
        "id": "05_privacy_storage",
        "eyebrow": "LOCAL STORAGE & PRIVACY",
        "headline_line1": "Your media.",
        "headline_line2": "Zero <span class=\"lit\">tracking.</span>",
        "subline": "Complete on-device privacy, local file manager, and bandwidth tools.",
        "screen_img": to_base64(os.path.join(SRC_DIR, "05_data_usage.png")),
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
    width: 1320px;
    height: 2868px;
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
    background-image: radial-gradient(circle at 1.5px 1.5px, rgba(255, 255, 255, 0.12) 1.3px, transparent 1.9px);
    background-size: 44px 44px;
    background-position: 22px 10px;
    -webkit-mask: radial-gradient(ellipse 62% 42% at 50% 30%, #000 10%, rgba(0,0,0,0.35) 55%, transparent 80%),
                 linear-gradient(180deg, #000 0, #000 220px, transparent 250px, transparent 720px, #000 760px);
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
    top: -260px;
    width: 1720px;
    height: 520px;
    filter: blur(35px);
    background: radial-gradient(ellipse 34% 50% at 50% 50%, rgba(130,124,255,0.55), rgba(130,124,255,0.12) 55%, transparent 75%);
    pointer-events: none;
  }}

  /* Indigo-violet light beam from top */
  .beam-wide {{
    position: absolute;
    inset: -240px;
    filter: blur(46px);
    background: conic-gradient(from 160deg at 900px 60px, transparent 0deg,
      rgba(110,106,255,0.10) 9deg, rgba(150,120,255,0.22) 20deg, rgba(110,106,255,0.10) 31deg, transparent 40deg);
    -webkit-mask: linear-gradient(180deg, rgba(0,0,0,0.55) 0%, #000 30%, #000 55%, transparent 88%);
    mix-blend-mode: screen;
    pointer-events: none;
  }}

  .beam-core {{
    position: absolute;
    inset: -240px;
    filter: blur(16px);
    background: conic-gradient(from 173.5deg at 900px 60px, transparent 0deg,
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
    width: 1320px;
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
    padding-top: 140px;
    z-index: 10;
  }}

  /* Eyebrow - Figtree only, NO double slashes (//) */
  .eyebrow {{
    font-family: 'Figtree', sans-serif;
    font-size: 26px;
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
    font-size: 144px;
    line-height: 1.04;
    letter-spacing: -0.035em;
    margin-top: 28px;
    padding-bottom: 0.08em;
    background: linear-gradient(180deg, #FFFFFF 0%, #FFFFFF 38%, #B9BDC9 100%);
    -webkit-background-clip: text;
    background-clip: text;
    color: transparent;
    max-width: 1200px;
  }}

  .headline .lit {{
    background: linear-gradient(180deg, #E2E0FF 0%, #C2BFFF 55%, #B3AFFF 100%);
    -webkit-background-clip: text;
    background-clip: text;
    color: transparent;
  }}

  .subline {{
    font-family: 'Figtree', sans-serif;
    font-size: 40px;
    font-weight: 400;
    line-height: 1.34;
    letter-spacing: -0.01em;
    color: #B4B9C6;
    margin-top: 24px;
    max-width: 1080px;
  }}

  /* Floor Line & Floor Reflection */
  .floor-line {{
    position: absolute;
    top: 2776px;
    left: 0;
    width: 100%;
    height: 2px;
    background: linear-gradient(90deg, transparent 4%, rgba(185,182,255,0.45) 30%, rgba(210,208,255,0.7) 50%, rgba(185,182,255,0.45) 70%, transparent 96%);
    z-index: 5;
  }}

  .floor-glow {{
    position: absolute;
    left: 60px;
    top: 2690px;
    width: 1200px;
    height: 180px;
    filter: blur(28px);
    background: radial-gradient(ellipse at 50% 50%, rgba(124,120,255,0.32), transparent 70%);
    pointer-events: none;
    z-index: 4;
  }}

  /* Phone Container */
  .phone-stage {{
    position: absolute;
    left: 170px;
    top: 780px;
    width: 980px;
    height: 1996px;
    z-index: 20;
  }}

  /* Bezel Halo & Bloom */
  .phone-halo {{
    position: absolute;
    inset: -6px;
    border-radius: 13.4% / 6.6%;
    filter: blur(10px);
    background: linear-gradient(180deg, rgba(200,196,255,0.95) 0%, rgba(160,156,255,0.55) 6%, rgba(143,140,255,0) 26%);
    pointer-events: none;
    z-index: 1;
  }}

  .phone-bloom {{
    position: absolute;
    left: 10%;
    right: 10%;
    top: -120px;
    height: 420px;
    filter: blur(70px);
    background: radial-gradient(ellipse at 50% 60%, rgba(143,140,255,0.55), transparent 70%);
    pointer-events: none;
    z-index: 2;
  }}

  .phone-wrapper {{
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
    z-index: 10;
    pointer-events: none;
  }}

  /* Inner Screen */
  .screen-frame {{
    position: absolute;
    left: 5.088%;
    top: 2.209%;
    width: 89.824%;
    height: 95.581%;
    border-radius: 68px;
    overflow: hidden;
    background: #000;
    z-index: 20;
  }}

  .screen-img {{
    width: 100%;
    height: 100%;
    object-fit: cover;
    object-position: top;
    display: block;
  }}

  /* Reflection under phone */
  .reflection {{
    position: absolute;
    left: 170px;
    top: 2778px;
    width: 980px;
    height: 220px;
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
    height: 1996px;
    display: block;
  }}

  /* Dark Glass Tech Spec Card - Smaller, Sleeker, Placed Top 20% or Bottom 20% */
  .tech-chip {{
    position: absolute;
    width: 440px;
    border-radius: 20px;
    background: linear-gradient(180deg, rgba(22,25,35,0.90), rgba(13,15,22,0.85));
    backdrop-filter: blur(28px) saturate(140%);
    -webkit-backdrop-filter: blur(28px) saturate(140%);
    box-shadow: inset 0 1px 0 rgba(255,255,255,0.14),
                0 0 0 1px rgba(0,0,0,0.65),
                0 25px 50px -10px rgba(0,0,0,0.85),
                0 0 35px -8px rgba(124,120,255,0.25);
    padding: 18px 24px;
    z-index: 35;
    border: 1px solid rgba(206,202,255,0.24);
  }}

  .tech-chip.left {{
    left: -50px;
  }}

  .tech-chip.right {{
    right: -50px;
  }}

  .chip-status {{
    font-family: 'Figtree', sans-serif;
    font-size: 16px;
    font-weight: 700;
    color: #B3AFFF;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 6px;
  }}

  .chip-status .dot {{
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: #8F8CFF;
    box-shadow: 0 0 10px #8F8CFF;
  }}

  .chip-title {{
    font-family: 'Figtree', sans-serif;
    font-size: 26px;
    font-weight: 700;
    letter-spacing: -0.02em;
    color: #F4F5F8;
    line-height: 1.15;
    margin-bottom: 6px;
  }}

  .chip-meta {{
    font-family: 'Figtree', sans-serif;
    font-size: 16px;
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

  <!-- Phone Stage -->
  <div class="phone-stage">
    <div class="phone-halo"></div>
    <div class="phone-bloom"></div>
    <div class="phone-wrapper">
      <div class="screen-frame">
        <img class="screen-img" src="{screen_img}">
      </div>
      <img class="mockup-img" src="{mockup_b64}">
    </div>

    <!-- Tech Spec Glass Card - Placed over screen at top 20% or bottom 20% -->
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
    <img src="{mockup_b64}">
  </div>
</body>
</html>
"""

if __name__ == "__main__":
    # Render slides (optionally filtered by command line argument)
    target_filter = sys.argv[1].lower() if len(sys.argv) > 1 else None

    for slide in slides:
        if target_filter and target_filter not in slide["id"].lower():
            continue
        html_content = HTML_TEMPLATE.format(
            eyebrow=slide["eyebrow"],
            headline_line1=slide["headline_line1"],
            headline_line2=slide["headline_line2"],
            subline=slide["subline"],
            screen_img=slide["screen_img"],
            mockup_b64=mockup_b64,
            chip_pos=slide["chip_pos"],
            chip_vertical=slide["chip_vertical"],
            chip_status=slide["chip_status"],
            chip_title=slide["chip_title"],
            chip_meta=slide["chip_meta"]
        )
        
        html_path = f"/tmp/{slide['id']}.html"
        with open(html_path, "w") as f:
            f.write(html_content)
            
        out_png_6_9 = os.path.join(OUT_6_9, f"{slide['id']}.png")
        
        cmd = [
            "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
            "--headless",
            "--disable-gpu",
            "--hide-scrollbars",
            "--window-size=1320,2868",
            "--virtual-time-budget=3500",
            f"--screenshot={out_png_6_9}",
            html_path
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        # Generate 6.5" downscaled version (1284 x 2778)
        im = Image.open(out_png_6_9)
        im_6_5 = im.resize((1284, 2778), Image.Resampling.LANCZOS)
        out_png_6_5 = os.path.join(OUT_6_5, f"{slide['id']}.png")
        im_6_5.save(out_png_6_5, "PNG", optimize=True)
        
        print(f"Generated {slide['id']}: 6.9\" ({im.size}) and 6.5\" ({im_6_5.size})")

    print("All screenshots generated successfully with Figtree font, no double slashes, and compact top/bottom 20% overlays!")

