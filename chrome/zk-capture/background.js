const HOST = "top.homeward_sky.zk_capture";

function isPdfUrl(url) {
  try {
    const parsed = new URL(url);
    return /\.pdf($|[?#])/i.test(parsed.pathname) || parsed.pathname.toLowerCase().includes("/pdf/");
  } catch (_) {
    return /\.pdf($|[?#])/i.test(url || "");
  }
}

function notify(title, message) {
  chrome.notifications.create({
    type: "basic",
    iconUrl: "icon.svg",
    title,
    message: message || "",
  });
}

function sendNative(payload) {
  return new Promise((resolve, reject) => {
    chrome.runtime.sendNativeMessage(HOST, payload, (response) => {
      const err = chrome.runtime.lastError;
      if (err) {
        reject(new Error(err.message));
        return;
      }
      resolve(response || { ok: false, error: "empty native host response" });
    });
  });
}

async function getSelection(tabId) {
  try {
    const [result] = await chrome.scripting.executeScript({
      target: { tabId },
      func: () => window.getSelection()?.toString() || "",
    });
    return result?.result || "";
  } catch (_) {
    return "";
  }
}

async function capturePage(tab) {
  const selection = tab.id ? await getSelection(tab.id) : "";
  const response = await sendNative({
    action: "capturePage",
    url: tab.url,
    title: tab.title || "",
    selection,
  });
  report(response, "Page captured");
  return response;
}

async function capturePdfUrl(url, title = "") {
  const response = await sendNative({
    action: "capturePdfUrl",
    url,
    title,
  });
  report(response, "PDF captured");
  return response;
}

async function captureActivePdf(tab) {
  const response = await capturePdfUrl(tab.url, tab.title || "");
  return response;
}

async function captureAuto(tab) {
  if (isPdfUrl(tab.url || "")) {
    return captureActivePdf(tab);
  }
  return capturePage(tab);
}

function report(response, successTitle) {
  if (response?.ok) {
    if (response.status === "exists") {
      notify("Already captured", `@${response.key || "unknown"}`);
    } else {
      notify(successTitle, response.title || response.note_path || "Done");
    }
  } else {
    notify("ZK Capture failed", response?.error || "Unknown error");
  }
}

chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "zk-capture-page",
    title: "Capture page to ZK",
    contexts: ["page"],
  });
  chrome.contextMenus.create({
    id: "zk-capture-link-pdf",
    title: "Capture linked PDF to ZK",
    contexts: ["link"],
  });
});

chrome.contextMenus.onClicked.addListener(async (info, tab) => {
  try {
    if (info.menuItemId === "zk-capture-page" && tab) {
      await capturePage(tab);
    } else if (info.menuItemId === "zk-capture-link-pdf" && info.linkUrl) {
      await capturePdfUrl(info.linkUrl, info.selectionText || tab?.title || "");
    }
  } catch (error) {
    notify("ZK Capture failed", error.message);
  }
});

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  (async () => {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    if (!tab) throw new Error("No active tab");
    if (message.action === "capturePage") return capturePage(tab);
    if (message.action === "capturePdf") return captureActivePdf(tab);
    if (message.action === "captureAuto") return captureAuto(tab);
    if (message.action === "ping") return sendNative({ action: "ping" });
    throw new Error(`Unknown action: ${message.action}`);
  })()
    .then((response) => sendResponse(response))
    .catch((error) => sendResponse({ ok: false, error: error.message }));
  return true;
});
