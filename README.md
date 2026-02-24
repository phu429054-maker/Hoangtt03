<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>HOANGTT.03 - HEX OBFUSCATOR</title>
  <style>
    * { margin:0; padding:0; box-sizing:border-box; }
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
      color: #e0e0ff;
      min-height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;
      padding: 15px;
    }
    .container {
      background: rgba(20, 20, 40, 0.95);
      border-radius: 16px;
      padding: 25px;
      width: 100%;
      max-width: 600px;
      box-shadow: 0 10px 40px rgba(0,0,0,0.8);
      border: 1px solid rgba(0,255,200,0.3);
    }
    h1 {
      text-align: center;
      color: #00ffc8;
      margin-bottom: 20px;
      font-size: 2rem;
      text-shadow: 0 0 15px #00ffc8;
    }
    .section {
      margin-bottom: 20px;
    }
    label {
      display: block;
      margin-bottom: 6px;
      color: #a0a0ff;
      font-weight: 600;
      font-size: 1.1rem;
    }
    textarea, pre {
      width: 100%;
      min-height: 140px;
      background: #0d0d1f;
      border: 1px solid #444466;
      border-radius: 10px;
      padding: 12px;
      color: #e0e0ff;
      font-family: 'Courier New', monospace;
      font-size: 13px;
      resize: vertical;
      white-space: pre-wrap;
      word-break: break-all;
    }
    pre {
      margin-top: 6px;
      cursor: pointer;
      user-select: text;
    }
    pre:hover {
      background: #1a1a3a;
    }
    .buttons {
      display: flex;
      gap: 10px;
      justify-content: center;
      margin: 20px 0;
      flex-wrap: wrap;
    }
    button {
      padding: 12px 24px;
      font-size: 15px;
      font-weight: bold;
      border: none;
      border-radius: 10px;
      cursor: pointer;
      transition: all 0.3s;
    }
    #obfuscateBtn {
      background: linear-gradient(90deg, #ff6b6b, #ff8e53);
      color: white;
    }
    #obfuscateBtn:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 15px rgba(255,107,107,0.5);
    }
    #downloadBtn {
      background: linear-gradient(90deg, #00c9ff, #92fe9d);
      color: #000;
    }
    #downloadBtn:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 15px rgba(0,201,255,0.5);
    }
    #clearBtn {
      background: #444466;
      color: white;
    }
    #clearBtn:hover {
      background: #666688;
    }
    footer {
      text-align: center;
      margin-top: 20px;
      color: #8888aa;
      font-size: 0.9rem;
    }
  </style>
</head>
<body>

  <div class="container">
    <h1>HOANGTT.03 - HEX OBFUSCATOR</h1>

    <div class="section">
      <label>DÁN SCRIPT GỐC VÀO ĐÂY</label>
      <textarea id="input" placeholder="Paste script Lua/Luau của bạn vào đây..."></textarea>
    </div>

    <div class="buttons">
      <button id="obfuscateBtn">MÃ HÓA HEX</button>
      <button id="downloadBtn">TẢI XUỐNG CODE</button>
      <button id="clearBtn">CLEAR</button>
    </div>

    <div class="section">
      <label>KẾT QUẢ MÃ HÓA (Nhấn giữ để xem)</label>
      <pre id="output">Kết quả sẽ hiện tại đây sau khi bấm MÃ HÓA HEX...</pre>
    </div>

    <footer>
      Powered by hoangtt.03 • 2026 • discord.gg/hoangtt03
    </footer>
  </div>

  <script>
    const input = document.getElementById("input");
    const output = document.getElementById("output");
    const obfuscateBtn = document.getElementById("obfuscateBtn");
    const downloadBtn = document.getElementById("downloadBtn");
    const clearBtn = document.getElementById("clearBtn");

    function toHex(str) {
      let hex = "";
      for (let i = 0; i < str.length; i++) {
        hex += str.charCodeAt(i).toString(16).padStart(2, "0");
      }
      return hex;
    }

    function generateObfuscatedCode(hex) {
      return `--[[ 
    SECURED BY HOANGTT.03 
    Status: Protected & Encrypted 
    Discord: https://discord.gg/v9P777smu
]]
local _raw = "${hex}"
local _exec = ""
for i = 1, #_raw, 2 do
    _exec = _exec .. string.char(tonumber(_raw:sub(i, i+1), 16))
end
local _run, _err = loadstring(_exec)
if _run then
    _run()
else
    warn("Error: " .. (_err or "Unknown"))
end`;
    }

    obfuscateBtn.addEventListener("click", () => {
      const code = input.value.trim();
      if (!code) {
        output.textContent = "Vui lòng dán script vào ô trên!";
        return;
      }
      const hex = toHex(code);
      const obfuscated = generateObfuscatedCode(hex);
      output.textContent = obfuscated;
    });

    downloadBtn.addEventListener("click", () => {
      const content = output.textContent.trim();
      if (content === "" || content.includes("Vui lòng dán") || content.includes("Kết quả sẽ hiện")) {
        alert("Chưa có code để tải! Bấm MÃ HÓA HEX trước nhé.");
        return;
      }

      const blob = new Blob([content], { type: "text/plain" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = "obfuscated_by_hoangtt.03.lua";
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      alert("ĐÃ TẢI FILE! File tên: obfuscated_by_hoangtt.03.lua");
    });

    clearBtn.addEventListener("click", () => {
      input.value = "";
      output.textContent = "Kết quả sẽ hiện tại đây sau khi bấm MÃ HÓA HEX...";
    });

    // Nhấn giữ để chọn text (hỗ trợ copy thủ công trên mobile)
    output.addEventListener("touchstart", function(e) {
      e.preventDefault();
      const range = document.createRange();
      range.selectNodeContents(this);
      const selection = window.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
    });
  </script>
</body>
</html>
