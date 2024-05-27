import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "My Web Server in Assembly",
  titleTemplate: ":title - My Web Server in Assembly",
  description:
    "This project is a simple web server written in assembly language for AMD64 architecture.",
  lang: "en-US",
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [{ text: "Home", link: "/" }],

    sidebar: [
      {
        text: "Getting Started",
        items: [{ text: "Introduction", link: "/introduction" }],
      },
      {
        text: "Assembly",
        link: "/assembly/",
        items: [
          { text: "Instructions", link: "/assembly/instructions" },
          { text: "Jump Instructions", link: "/assembly/jump-instructions" },
        ],
      },
    ],

    outline: {
      level: [2, 4],
    },

    externalLinkIcon: true,

    search: {
      provider: "local",
    },

    socialLinks: [
      {
        icon: "github",
        link: "https://github.com/Codycody31/AssemblyWebServer",
      },
    ],
  },
});
