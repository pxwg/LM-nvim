const statusEl = document.getElementById("status");

function setStatus(value) {
  statusEl.textContent = typeof value === "string" ? value : JSON.stringify(value, null, 2);
}

async function send(action) {
  setStatus("Working...");
  const response = await chrome.runtime.sendMessage({ action });
  setStatus(response);
}

document.getElementById("auto").addEventListener("click", () => send("captureAuto"));
document.getElementById("page").addEventListener("click", () => send("capturePage"));
document.getElementById("pdf").addEventListener("click", () => send("capturePdf"));
document.getElementById("ping").addEventListener("click", () => send("ping"));
