(() => {
  "use strict";

  const CHAPTERS = [
    {
      id: "README",
      file: "README.md",
      number: "00",
      title: "Guide Home",
      documentTitle: "GenDev Practitioner Guide",
      group: "Start here",
    },
    { id: "01-orientation", file: "01-orientation.md", number: "01", title: "Orientation", group: "Foundations" },
    { id: "02-core-mental-model", file: "02-core-mental-model.md", number: "02", title: "Core Mental Model", group: "Foundations" },
    { id: "03-repository-map", file: "03-repository-map.md", number: "03", title: "Repository Map", group: "Foundations" },
    { id: "04-starting-a-new-project", file: "04-starting-a-new-project.md", number: "04", title: "Starting A New Project", group: "Foundations" },
    { id: "05-working-with-the-agent", file: "05-working-with-the-agent.md", number: "05", title: "Working With The Agent", group: "Foundations" },
    { id: "06-gates-and-artifacts", file: "06-gates-and-artifacts.md", number: "06", title: "Gates And Artifacts", group: "Foundations" },
    { id: "07-approvals-and-risk", file: "07-approvals-and-risk.md", number: "07", title: "Approvals And Risk", group: "Foundations" },
    { id: "08-subagents-and-delegation", file: "08-subagents-and-delegation.md", number: "08", title: "Subagents And Delegation", group: "Delivery" },
    { id: "09-build-planning-and-implementation", file: "09-build-planning-and-implementation.md", number: "09", title: "Build Planning And Implementation", group: "Delivery" },
    { id: "10-review-remediation-and-closeout", file: "10-review-remediation-and-closeout.md", number: "10", title: "Review, Remediation, And Close-Out", group: "Delivery" },
    { id: "11-production-operations", file: "11-production-operations.md", number: "11", title: "Production Operations", group: "Delivery" },
    { id: "12-vendor-contract-tracker-walkthrough", file: "12-vendor-contract-tracker-walkthrough.md", number: "12", title: "Vendor Contract Tracker Walkthrough", group: "Reference" },
    { id: "13-codex-specific-notes", file: "13-codex-specific-notes.md", number: "13", title: "Codex-Specific Notes", group: "Reference" },
    { id: "14-claude-code-specific-notes", file: "14-claude-code-specific-notes.md", number: "14", title: "Claude Code-Specific Notes", group: "Reference" },
    { id: "15-prompt-library", file: "15-prompt-library.md", number: "15", title: "Prompt Library", group: "Reference" },
    { id: "16-checklists", file: "16-checklists.md", number: "16", title: "Checklists", group: "Reference" },
    { id: "17-common-failure-modes", file: "17-common-failure-modes.md", number: "17", title: "Common Failure Modes", group: "Reference" },
    { id: "18-glossary", file: "18-glossary.md", number: "18", title: "Glossary", group: "Reference" },
    { id: "19-starting-mid-stream", file: "19-starting-mid-stream.md", number: "19", title: "Starting Mid-Stream", group: "Appendix" },
  ];

  const chapterById = new Map(CHAPTERS.map((chapter) => [chapter.id, chapter]));
  const chapterByFile = new Map(CHAPTERS.map((chapter) => [chapter.file, chapter]));
  const documentCache = new Map();
  const content = document.querySelector("#guide-content");
  const chapterNav = document.querySelector("#chapter-nav");
  const chapterPager = document.querySelector("#chapter-pager");
  const chapterLocation = document.querySelector("#chapter-location");
  const pageToc = document.querySelector("#page-toc");
  const readingTime = document.querySelector("#reading-time");
  const readingProgress = document.querySelector("#reading-progress-bar");
  const searchInput = document.querySelector("#guide-search");
  const searchResults = document.querySelector("#search-results");
  const searchShell = document.querySelector("#search-shell");
  const menuToggle = document.querySelector("#menu-toggle");
  const sidebarBackdrop = document.querySelector("#sidebar-backdrop");
  const themeToggle = document.querySelector("#theme-toggle");
  const themeColor = document.querySelector('meta[name="theme-color"]');
  const systemTheme = window.matchMedia("(prefers-color-scheme: dark)");
  let currentChapterId = "README";
  let searchSequence = 0;
  let tocObserver = null;
  let scrollFrame = null;

  function chapterUrl(id, hash = "") {
    if (id === "README") {
      return hash ? `./${hash}` : "./";
    }
    return `./?chapter=${encodeURIComponent(id)}${hash}`;
  }

  function selectedChapterFromUrl() {
    const value = new URL(window.location.href).searchParams.get("chapter") || "README";
    return chapterById.has(value) ? value : "README";
  }

  function createElement(tag, className, text) {
    const element = document.createElement(tag);
    if (className) element.className = className;
    if (text !== undefined) element.textContent = text;
    return element;
  }

  function buildNavigation() {
    const groups = new Map();
    for (const chapter of CHAPTERS) {
      if (!groups.has(chapter.group)) groups.set(chapter.group, []);
      groups.get(chapter.group).push(chapter);
    }

    const fragment = document.createDocumentFragment();
    for (const [groupName, chapters] of groups) {
      const section = createElement("section", "nav-group");
      section.append(createElement("h2", "nav-group-title", groupName));
      for (const chapter of chapters) {
        const link = createElement("a", "chapter-nav-link");
        link.href = chapterUrl(chapter.id);
        link.dataset.chapter = chapter.id;
        link.append(createElement("span", "nav-number", chapter.number));
        link.append(createElement("span", "nav-title", chapter.title));
        section.append(link);
      }
      fragment.append(section);
    }
    chapterNav.replaceChildren(fragment);
  }

  async function loadMarkdown(chapter) {
    if (!documentCache.has(chapter.id)) {
      // here.now presents Markdown paths with a rich viewer by default. The raw query keeps the
      // canonical Markdown available to this client renderer and is ignored by ordinary file
      // servers during local development.
      const request = fetch(`content/${chapter.file}?raw=1`).then(async (response) => {
        if (!response.ok) {
          throw new Error(`Could not load ${chapter.file} (HTTP ${response.status}).`);
        }
        return response.text();
      });
      documentCache.set(chapter.id, request);
    }
    return documentCache.get(chapter.id);
  }

  function slugify(value) {
    return value
      .toLowerCase()
      .normalize("NFKD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/[^a-z0-9\s-]/g, "")
      .trim()
      .replace(/\s+/g, "-")
      .replace(/-+/g, "-") || "section";
  }

  function sanitizeRenderedContent(root) {
    root.querySelectorAll("script, iframe, object, embed, link, style, form").forEach((element) => element.remove());
    root.querySelectorAll("*").forEach((element) => {
      for (const attribute of [...element.attributes]) {
        const name = attribute.name.toLowerCase();
        const value = attribute.value.trim().toLowerCase();
        if (name.startsWith("on") || name === "srcdoc") {
          element.removeAttribute(attribute.name);
        }
        if ((name === "href" || name === "src") && (value.startsWith("javascript:") || value.startsWith("data:text/html"))) {
          element.removeAttribute(attribute.name);
        }
      }
    });
  }

  function enhanceHeadings(root) {
    const identifiers = new Map();
    const headings = [...root.querySelectorAll("h1, h2, h3, h4")];
    for (const heading of headings) {
      const baseId = slugify(heading.textContent);
      const count = identifiers.get(baseId) || 0;
      identifiers.set(baseId, count + 1);
      heading.id = count === 0 ? baseId : `${baseId}-${count + 1}`;
      if (heading.tagName !== "H1") {
        const anchor = createElement("a", "heading-anchor", "#");
        anchor.href = `#${heading.id}`;
        anchor.setAttribute("aria-label", `Link to ${heading.textContent}`);
        heading.prepend(anchor);
      }
    }
    return headings;
  }

  function enhanceLinks(root) {
    root.querySelectorAll("a[href]").forEach((link) => {
      const href = link.getAttribute("href");
      if (!href) return;
      const markdownMatch = href.match(/^([^#]+\.md)(#[\s\S]*)?$/);
      if (markdownMatch && chapterByFile.has(markdownMatch[1])) {
        const target = chapterByFile.get(markdownMatch[1]);
        link.href = chapterUrl(target.id, markdownMatch[2] || "");
        link.dataset.chapter = target.id;
        return;
      }
      if (/^https?:\/\//i.test(href)) {
        link.target = "_blank";
        link.rel = "noopener noreferrer";
      }
    });
  }

  function enhanceDocumentMetadata(root, chapter) {
    if (chapter.id !== "README") return;
    const lead = root.querySelector("h1 + p");
    if (!lead) return;
    const match = lead.textContent.match(/^Status:\s*(.*?)\s+Audience:\s*([\s\S]+)$/);
    if (!match) return;

    const status = createElement("span", "document-meta-item");
    status.append(createElement("strong", "", "Status"), document.createTextNode(match[1]));
    const audience = createElement("span", "document-meta-item");
    audience.append(createElement("strong", "", "Audience"), document.createTextNode(match[2]));
    lead.className = "document-meta";
    lead.replaceChildren(status, audience);
  }

  function enhanceCodeBlocks(root) {
    root.querySelectorAll("pre").forEach((pre) => {
      if (pre.closest(".mermaid-shell") || pre.closest(".code-shell")) return;
      const shell = createElement("div", "code-shell");
      const button = createElement("button", "copy-code", "Copy");
      button.type = "button";
      button.setAttribute("aria-label", "Copy code block");
      pre.before(shell);
      shell.append(pre, button);
      button.addEventListener("click", async () => {
        const code = pre.querySelector("code")?.textContent || pre.textContent;
        try {
          await navigator.clipboard.writeText(code);
          button.textContent = "Copied";
          window.setTimeout(() => { button.textContent = "Copy"; }, 1600);
        } catch {
          button.textContent = "Select text";
        }
      });
    });
  }

  async function renderMermaid(root) {
    const blocks = [...root.querySelectorAll("pre code.language-mermaid")];
    if (blocks.length === 0) return;

    const nodes = blocks.map((code) => {
      const source = code.textContent;
      const pre = code.closest("pre");
      const shell = createElement("div", "mermaid-shell");
      const diagram = createElement("div", "mermaid", source);
      shell.append(diagram);
      pre.replaceWith(shell);
      return diagram;
    });

    if (!window.mermaid) {
      nodes.forEach((node) => {
        node.className = "mermaid-error";
        node.textContent = "Mermaid could not load. The diagram source is unavailable in rendered mode.";
      });
      return;
    }

    try {
      window.mermaid.initialize({
        startOnLoad: false,
        securityLevel: "strict",
        theme: document.documentElement.dataset.theme === "dark" ? "dark" : "neutral",
        fontFamily: "Inter, ui-sans-serif, system-ui, sans-serif",
      });
      await window.mermaid.run({ nodes, suppressErrors: true });
    } catch (error) {
      nodes.forEach((node) => {
        if (node.querySelector("svg")) return;
        node.className = "mermaid-error";
        node.textContent = `Mermaid diagram error: ${error.message}`;
      });
    }
  }

  function buildPageToc(headings) {
    if (tocObserver) tocObserver.disconnect();
    const tocHeadings = headings.filter((heading) => heading.tagName === "H2" || heading.tagName === "H3");
    if (tocHeadings.length === 0) {
      pageToc.replaceChildren(createElement("p", "toc-empty", "No sections on this page."));
      return;
    }

    const fragment = document.createDocumentFragment();
    for (const heading of tocHeadings) {
      const link = createElement("a", "toc-link", heading.textContent.replace(/^#/, "").trim());
      link.href = `#${heading.id}`;
      link.dataset.depth = heading.tagName.slice(1);
      link.dataset.heading = heading.id;
      fragment.append(link);
    }
    pageToc.replaceChildren(fragment);

    tocObserver = new IntersectionObserver((entries) => {
      const visible = entries
        .filter((entry) => entry.isIntersecting)
        .sort((left, right) => left.boundingClientRect.top - right.boundingClientRect.top);
      if (visible.length === 0) return;
      pageToc.querySelectorAll(".toc-link").forEach((link) => {
        link.classList.toggle("active", link.dataset.heading === visible[0].target.id);
      });
    }, { rootMargin: "-90px 0px -72% 0px", threshold: [0, 1] });

    tocHeadings.forEach((heading) => tocObserver.observe(heading));
  }

  function buildPager(chapter) {
    const index = CHAPTERS.findIndex((candidate) => candidate.id === chapter.id);
    const previous = CHAPTERS[index - 1];
    const next = CHAPTERS[index + 1];
    const fragment = document.createDocumentFragment();

    if (previous) {
      const link = createElement("a", "pager-link previous");
      link.href = chapterUrl(previous.id);
      link.dataset.chapter = previous.id;
      link.append(createElement("span", "pager-arrow", "←"));
      const copy = createElement("span", "pager-copy");
      copy.append(createElement("small", "", "Previous"), createElement("strong", "", previous.title));
      link.append(copy);
      fragment.append(link);
    }
    if (next) {
      const link = createElement("a", "pager-link next");
      link.href = chapterUrl(next.id);
      link.dataset.chapter = next.id;
      const copy = createElement("span", "pager-copy");
      copy.append(createElement("small", "", "Next"), createElement("strong", "", next.title));
      link.append(copy, createElement("span", "pager-arrow", "→"));
      fragment.append(link);
    }
    chapterPager.replaceChildren(fragment);
  }

  function updateCurrentNavigation(chapter) {
    chapterNav.querySelectorAll("[data-chapter]").forEach((link) => {
      if (link.dataset.chapter === chapter.id) {
        link.setAttribute("aria-current", "page");
      } else {
        link.removeAttribute("aria-current");
      }
    });
  }

  function updateReadingProgress() {
    scrollFrame = null;
    const start = content.offsetTop - 120;
    const end = start + content.offsetHeight - window.innerHeight * 0.72;
    const distance = Math.max(1, end - start);
    const value = Math.min(1, Math.max(0, (window.scrollY - start) / distance));
    readingProgress.style.width = `${value * 100}%`;
  }

  function scheduleReadingProgress() {
    if (scrollFrame === null) scrollFrame = window.requestAnimationFrame(updateReadingProgress);
  }

  function showLoadingState() {
    content.setAttribute("aria-busy", "true");
    const loading = createElement("div", "loading-state");
    loading.setAttribute("aria-label", "Loading chapter");
    loading.append(document.createElement("span"), document.createElement("span"), document.createElement("span"), document.createElement("span"));
    content.replaceChildren(loading);
  }

  async function renderChapter(id, options = {}) {
    const chapter = chapterById.get(id) || chapterById.get("README");
    const preserveScroll = options.preserveScroll === true;
    const oldScroll = window.scrollY;
    currentChapterId = chapter.id;
    showLoadingState();
    closeNavigation();
    closeSearch();
    updateCurrentNavigation(chapter);
    chapterLocation.textContent = chapter.title;
    readingTime.textContent = "Loading…";
    document.title = chapter.id === "README"
      ? "GenDev Practitioner Guide"
      : `${chapter.documentTitle || chapter.title} · GenDev Practitioner Guide`;

    try {
      const markdown = await loadMarkdown(chapter);
      if (currentChapterId !== chapter.id) return;
      if (!window.marked?.parse) throw new Error("The Markdown renderer did not load.");

      const rendered = window.marked.parse(markdown, { gfm: true, breaks: false });
      content.innerHTML = rendered;
      sanitizeRenderedContent(content);
      const headings = enhanceHeadings(content);
      enhanceDocumentMetadata(content, chapter);
      enhanceLinks(content);
      await renderMermaid(content);
      enhanceCodeBlocks(content);
      buildPageToc(headings);
      buildPager(chapter);
      const wordCount = markdown.trim().split(/\s+/).length;
      readingTime.textContent = `${Math.max(1, Math.ceil(wordCount / 225))} min read`;
      content.removeAttribute("aria-busy");

      if (preserveScroll) {
        window.scrollTo({ top: oldScroll });
      } else if (window.location.hash) {
        window.requestAnimationFrame(() => {
          document.getElementById(decodeURIComponent(window.location.hash.slice(1)))?.scrollIntoView();
        });
      } else {
        window.scrollTo({ top: 0 });
      }
      scheduleReadingProgress();
    } catch (error) {
      const wrapper = createElement("div", "error-state");
      wrapper.append(createElement("h1", "", "This chapter could not be loaded"));
      wrapper.append(createElement("p", "", error.message));
      content.replaceChildren(wrapper);
      content.removeAttribute("aria-busy");
      readingTime.textContent = "Unavailable";
      pageToc.replaceChildren(createElement("p", "toc-empty", "No sections available."));
      chapterPager.replaceChildren();
    }
  }

  function navigateToChapter(id, hash = "") {
    const chapter = chapterById.get(id) || chapterById.get("README");
    window.history.pushState({ chapter: chapter.id }, "", chapterUrl(chapter.id, hash));
    renderChapter(chapter.id);
  }

  function plainText(markdown) {
    return markdown
      .replace(/```[\s\S]*?```/g, " ")
      .replace(/`([^`]+)`/g, "$1")
      .replace(/!\[([^\]]*)\]\([^)]*\)/g, "$1")
      .replace(/\[([^\]]+)\]\([^)]*\)/g, "$1")
      .replace(/^#{1,6}\s+/gm, "")
      .replace(/[*_~>|]/g, " ")
      .replace(/\s+/g, " ")
      .trim();
  }

  function appendHighlightedText(element, text, query) {
    const lower = text.toLowerCase();
    const index = lower.indexOf(query);
    if (index < 0) {
      element.textContent = text;
      return;
    }
    element.append(document.createTextNode(text.slice(0, index)));
    element.append(createElement("mark", "", text.slice(index, index + query.length)));
    element.append(document.createTextNode(text.slice(index + query.length)));
  }

  function makeSnippet(text, query) {
    const index = text.toLowerCase().indexOf(query);
    if (index < 0) return text.slice(0, 150);
    const start = Math.max(0, index - 58);
    const end = Math.min(text.length, index + query.length + 92);
    return `${start > 0 ? "…" : ""}${text.slice(start, end).trim()}${end < text.length ? "…" : ""}`;
  }

  async function searchGuide(rawQuery) {
    const sequence = ++searchSequence;
    const query = rawQuery.trim().toLowerCase();
    if (query.length < 2) {
      closeSearch();
      return;
    }

    searchResults.hidden = false;
    searchResults.replaceChildren(createElement("div", "search-empty", "Searching all chapters…"));
    searchInput.setAttribute("aria-expanded", "true");

    const loaded = await Promise.all(CHAPTERS.map(async (chapter) => ({ chapter, markdown: await loadMarkdown(chapter) })));
    if (sequence !== searchSequence || query !== searchInput.value.trim().toLowerCase()) return;

    const matches = loaded
      .map(({ chapter, markdown }) => {
        const text = plainText(markdown);
        const titleIndex = chapter.title.toLowerCase().indexOf(query);
        const textIndex = text.toLowerCase().indexOf(query);
        if (titleIndex < 0 && textIndex < 0) return null;
        const occurrences = text.toLowerCase().split(query).length - 1;
        return { chapter, text, score: (titleIndex >= 0 ? 100 : 0) + Math.min(occurrences, 25) };
      })
      .filter(Boolean)
      .sort((left, right) => right.score - left.score || Number(left.chapter.number) - Number(right.chapter.number))
      .slice(0, 9);

    if (matches.length === 0) {
      searchResults.replaceChildren(createElement("div", "search-empty", `No chapters match “${rawQuery.trim()}”.`));
      return;
    }

    const fragment = document.createDocumentFragment();
    for (const match of matches) {
      const link = createElement("a", "search-result");
      link.href = chapterUrl(match.chapter.id);
      link.dataset.chapter = match.chapter.id;
      const title = createElement("strong");
      appendHighlightedText(title, `${match.chapter.number} · ${match.chapter.title}`, query);
      const snippet = createElement("span");
      appendHighlightedText(snippet, makeSnippet(match.text, query), query);
      link.append(title, snippet);
      fragment.append(link);
    }
    searchResults.replaceChildren(fragment);
  }

  function closeSearch() {
    searchSequence += 1;
    searchResults.hidden = true;
    searchInput.setAttribute("aria-expanded", "false");
  }

  function openNavigation() {
    document.body.classList.add("nav-open");
    menuToggle.setAttribute("aria-expanded", "true");
    menuToggle.setAttribute("aria-label", "Close chapter navigation");
  }

  function closeNavigation() {
    document.body.classList.remove("nav-open");
    menuToggle.setAttribute("aria-expanded", "false");
    menuToggle.setAttribute("aria-label", "Open chapter navigation");
  }

  function storedTheme() {
    try {
      return window.localStorage.getItem("gendev-guide-theme");
    } catch {
      return null;
    }
  }

  function resolvedTheme() {
    return storedTheme() || (systemTheme.matches ? "dark" : "light");
  }

  function applyTheme(theme, save = false) {
    document.documentElement.dataset.theme = theme;
    themeToggle.setAttribute("aria-label", theme === "dark" ? "Switch to light theme" : "Switch to dark theme");
    themeColor.setAttribute("content", theme === "dark" ? "#101715" : "#f4f1ea");
    if (save) {
      try {
        window.localStorage.setItem("gendev-guide-theme", theme);
      } catch {
        // Theme persistence is optional.
      }
    }
  }

  document.addEventListener("click", (event) => {
    const chapterLink = event.target.closest("a[data-chapter]");
    if (chapterLink && chapterById.has(chapterLink.dataset.chapter)) {
      if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
      event.preventDefault();
      const url = new URL(chapterLink.href, window.location.href);
      navigateToChapter(chapterLink.dataset.chapter, url.hash);
      return;
    }
    if (!searchShell.contains(event.target)) closeSearch();
  });

  window.addEventListener("popstate", () => renderChapter(selectedChapterFromUrl()));
  window.addEventListener("scroll", scheduleReadingProgress, { passive: true });
  window.addEventListener("resize", scheduleReadingProgress);
  searchInput.addEventListener("input", () => searchGuide(searchInput.value));
  searchInput.addEventListener("focus", () => {
    if (searchInput.value.trim().length >= 2) searchGuide(searchInput.value);
  });
  menuToggle.addEventListener("click", () => {
    document.body.classList.contains("nav-open") ? closeNavigation() : openNavigation();
  });
  sidebarBackdrop.addEventListener("click", closeNavigation);
  themeToggle.addEventListener("click", () => {
    const theme = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
    applyTheme(theme, true);
    if (content.querySelector(".mermaid, .mermaid-shell svg")) {
      renderChapter(currentChapterId, { preserveScroll: true });
    }
  });
  systemTheme.addEventListener("change", () => {
    if (!storedTheme()) applyTheme(resolvedTheme());
  });
  document.addEventListener("keydown", (event) => {
    const tag = event.target.tagName;
    if (event.key === "/" && tag !== "INPUT" && tag !== "TEXTAREA" && tag !== "SELECT") {
      event.preventDefault();
      searchInput.focus();
    }
    if (event.key === "Escape") {
      closeSearch();
      closeNavigation();
      searchInput.blur();
    }
  });

  applyTheme(resolvedTheme());
  buildNavigation();
  renderChapter(selectedChapterFromUrl());
})();
