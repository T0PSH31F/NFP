(function () {
  const STYLE_ID = "noctalia-theme-override";

  function applyCachedTheme() {
    try {
      const css = localStorage.getItem("noctalia-theme-override");
      if (!css) return;

      let style = document.getElementById(STYLE_ID);
      if (!style) {
        style = document.createElement("style");
        style.id = STYLE_ID;
        (document.head || document.documentElement).appendChild(style);
      }
      style.textContent = css;
    } catch (e) {
      console.error("Noctalia Sync: failed to apply cached theme", e);
    }
  }

  applyCachedTheme();

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", applyCachedTheme);
  }
})();
