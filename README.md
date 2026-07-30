# 金管會重大裁罰案件統計

純靜態網頁，不需伺服器即可部署至 GitHub Pages。入口檔為 `index.html`，會開啟 `fsc-penalty-dashboard.html`。

## 使用方式

- 篩選條件變更時，統計數字、圖表與明細會即時更新。
- 「重新統計」會清除全部篩選條件，依完整資料集重新產生統計結果。

## 部署 GitHub Pages

1. 在 GitHub 建立一個新的公開 repository，例如 `fsc-penalty-dashboard`。
2. 將本資料夾推送至該 repository 的 `main` 分支。
3. 在 repository 的 **Settings → Pages**，選擇 **Deploy from a branch**，分支選 `main`、資料夾選 `/(root)`，然後儲存。
4. 等待 Pages 建置完成後，開啟 GitHub 顯示的網址。

網站網址會是 `https://<你的帳號>.github.io/fsc-penalty-dashboard/`。
