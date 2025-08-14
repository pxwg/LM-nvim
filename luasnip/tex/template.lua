local preamble = [[
%% ======================================================================
%% LaTeX Preamble for Physics Note, Experiment Report, and Research in
%% CJK and English
%% ======================================================================

%% ----------------------------------------------------------------------
%% 1. 文档基础设置与语言支持
%% ----------------------------------------------------------------------
\usepackage{geometry}
\geometry{a4paper,centering,scale=0.75} % 页面设置

% 中文支持 - 适配 macOS
% \usepackage[UTF8]{ctex}
% \AtBeginDocument{\small} % 全局缩小字体
% \setCJKmainfont[
%   Script=CJK,
%   BoldFont={Heiti SC},
%   ItalicFont={Kaiti SC}
% ]{Songti SC}

%% ----------------------------------------------------------------------
%% 2. 数学支持包
%% ----------------------------------------------------------------------
\usepackage{amsmath,amssymb,amsthm} % 数学基础支持
\usepackage{mathtools} % amsmath 扩展
\usepackage{physics} % 物理公式简化
\usepackage{mathrsfs} % 数学花体字
% \usepackage{bbm} % 黑板粗体
\usepackage{cancel} % 公式划除线
\numberwithin{equation}{section} % 按节编号公式
\usepackage[sc]{mathpazo}
\usepackage{courier}
\usepackage{inputenc}
\usepackage[T1]{fontenc}
\usepackage{microtype}
\RequirePackage[font=small,format=plain,labelfont=bf,textfont=it]{caption}

%% ----------------------------------------------------------------------
%% 3. 图形与绘图支持
%% ----------------------------------------------------------------------
\usepackage{graphicx} % 图片支持
\usepackage[export]{adjustbox} % 图片调整
\usepackage{float} % 控制浮动体
\usepackage{pgfplots} % 绘图支持
\pgfplotsset{compat=newest} % 使用最新版本特性
% \usepackage[compat=1.1.0,warn luatex=false]{tikz-feynman} % Feynman 图
\usepackage{tikz} % TikZ 绘图
\usetikzlibrary{arrows,shapes,positioning,calc,decorations.pathreplacing,patterns} % TikZ 库
\usepackage{tikz-cd} % commutative diagrams
\usepackage{quiver} % 交换图

%% ----------------------------------------------------------------------
%% 4. 表格支持
%% ----------------------------------------------------------------------
\usepackage{tabularx} % 增强表格
\usepackage{xltabular} % 长表格支持

%% ----------------------------------------------------------------------
%% 5. 交叉引用与超链接
%% ----------------------------------------------------------------------
% hyperref 通常放在最后加载以避免冲突
\usepackage[bookmarks=true, colorlinks=true, linkcolor=teal,
citecolor=blue, urlcolor=magenta, hidelinks]{hyperref}

%% ----------------------------------------------------------------------
%% 6. 外观与装饰
%% ----------------------------------------------------------------------
\usepackage{fancyhdr} % 页眉页脚
\usepackage[dvipsnames,svgnames]{xcolor} % 扩展颜色支持
\usepackage{framed} % 框架效果
\usepackage{tcolorbox} % 彩色文本框
\tcbuselibrary{most} % tcolorbox 扩展库
\usepackage[strict]{changepage} % 提供 adjustwidth 环境
\usepackage{scalerel} % 缩放支持

%% ----------------------------------------------------------------------
%% 7. 引用与杂项支持
%% ----------------------------------------------------------------------
\usepackage{enumerate} % 列表环境
\usepackage{stackrel} % 符号堆叠
\usepackage{import,xifthen,pdfpages} % 文档导入与条件判断
\usepackage{bookmark}

% 条件加载透明效果包 (仅在 PDF 模式下)
\usepackage{ifpdf}
\ifpdf
\usepackage{transparent}
\else
% 非 PDF 模式下使用替代方案或提供警告
\newcommand{\transparent}[1]{}
\typeout{警告：transparent 包功能在非 PDF 模式下不可用}
\fi

%% ----------------------------------------------------------------------
%% 8. 定理环境设置
%% ----------------------------------------------------------------------
% English theorem environments
\newtheorem{theorem}{Theorem}[section]
\newtheorem{lemma}[theorem]{Lemma}
\newtheorem{proposition}[theorem]{Proposition}
\newtheorem{corollary}[theorem]{Corollary}
\newtheorem{definition}{Definition}[section]
\newtheorem{remark}{Remark}[section]
\newtheorem{example}{Example}[section]
\newtheorem{construction}{Construction}[section]
\newenvironment{observation}{
\begin{proof}[Observation]}{
\end{proof}}
\newenvironment{solution}{
\begin{proof}[Solution]}{
\end{proof}}

%% ----------------------------------------------------------------------
%% 9. 自定义框架和环境
%% ----------------------------------------------------------------------
% 引用块样式
\definecolor{formalshade}{rgb}{0.95,0.95,1}
\newenvironment{quoteblock}{%
  \def\FrameCommand{%
    \hspace{1pt}%
    {\color{DarkBlue}\vrule width 2pt}%
    {\color{formalshade}\vrule width 4pt}%
    \colorbox{formalshade}%
  }%
  \MakeFramed{\advance\hsize-\width\FrameRestore}%
  \noindent\hspace{-4.55pt}%
  \begin{adjustwidth}{}{7pt}%
    \vspace{2pt}\vspace{2pt}%
  }
  {%
    \vspace{2pt}
  \end{adjustwidth}\endMakeFramed%
}

% 解答块样式
\definecolor{brownshade}{rgb}{0.99,0.97,0.93}
\newenvironment{solblock}{%
  \def\FrameCommand{%
    \hspace{1pt}%
    {\color{BurlyWood}\vrule width 2pt}%
    {\color{brownshade}\vrule width 4pt}%
    \colorbox{brownshade}%
  }%
  \MakeFramed{\advance\hsize-\width\FrameRestore}%
  \noindent\hspace{-4.55pt}%
  \begin{adjustwidth}{}{7pt}%
    \vspace{2pt}\vspace{2pt}%
  }
  {%
    \vspace{2pt}
  \end{adjustwidth}\endMakeFramed%
}

% 问题块样式
\definecolor{greenshade}{rgb}{0.90,0.99,0.91}
\newenvironment{quesblock}{%
  \def\FrameCommand{%
    \hspace{0.01pt}%
    {\color{Green}\vrule width 2pt}%
    {\color{greenshade}\vrule width 00.1pt}%
    \colorbox{greenshade}%
  }%
  \MakeFramed{\advance\hsize-\width\FrameRestore}%
  \noindent\hspace{-4.55pt}%
  \begin{adjustwidth}{}{7pt}%
    \vspace{2pt}\vspace{2pt}%
  }
  {%
    \vspace{2pt}
  \end{adjustwidth}\endMakeFramed%
}

% 标记块
\newtcolorbox{markerblock}[1][]{enhanced,
  before skip=2mm,after skip=3mm,
  boxrule=0.4pt,left=5mm,right=2mm,top=1mm,bottom=1mm,
  colback=yellow!20,
  colframe=yellow!40!black,
  sharp corners,rounded corners=southeast,arc is angular,arc=3mm,
  underlay={%
    \path[fill=tcbcolback!80!black] ([yshift=3mm]interior.south east)--++(-0.4,-0.1)--++(0.1,-0.2);
    \path[draw=tcbcolframe,shorten <=-0.05mm,shorten >=-0.05mm] ([yshift=3mm]interior.south east)--++(-0.4,-0.1)--++(0.1,-0.2);
    \path[fill=yellow!80!black,draw=none] (interior.south west) rectangle node[white]{\Huge\bfseries !} ([xshift=4mm]interior.north west);
  },
drop fuzzy shadow,#1}

% 提示块
\definecolor{tipscolor}{rgb}{0.77,0.72,0.65}
\newtcolorbox{tipsblock}[2][]
{enhanced,breakable,
  left=12pt,right=12pt,
  coltitle=white,
  colbacktitle=tipscolor,
  attach boxed title to top left={yshifttext=-1mm},
  boxed title style={skin=enhancedfirst jigsaw,arc=1mm,bottom=0mm,boxrule=0mm},
  boxrule=1pt,
  colback=OldLace,
  colframe=tipscolor,
  sharp corners=northwest,
  title=\vspace{3mm}\textbf{#2},
  arc=1mm,
#1}

% 定理类彩色块
\newenvironment{thmblock}[1][\textbf{Theorem}]{
\begin{tcolorbox}[title=\textbf{#1}, colback=red!5,colframe=red!75!black]}{
\end{tcolorbox}}

\newenvironment{defblock}[1][\textbf{Definition}]{
\begin{tcolorbox}[colback = Emerald!10, colframe = cyan!40!black, title = \textbf{#1}]}{
\end{tcolorbox}}

\newenvironment{lemmablock}[1][\textbf{Lemma}]{
\begin{tcolorbox}[title=\textbf{#1},colback=SeaGreen!10!CornflowerBlue!10,colframe=RoyalPurple!55!Aquamarine!100!]}{
\end{tcolorbox}}

\newenvironment{propblock}[1][\textbf{Proposition}]{
  \begin{tcolorbox}
  [title = \textbf{#1}, colback=Salmon!20, colframe=Salmon!90!Black]}{
\end{tcolorbox}}

\newenvironment{colblock}[1][\textbf{Collary}]{
\begin{tcolorbox}[colback=JungleGreen!10!Cerulean!15,colframe=CornflowerBlue!60!Black,title = \textbf{#1}]}{
\end{tcolorbox}}

% Mathematical operator definitions
\DeclareMathOperator{\im}{im}
\DeclareMathOperator{\coker}{coker}
\DeclareMathOperator{\ind}{ind}
\DeclareMathOperator{\diag}{diag}
\DeclareMathOperator{\sgn}{sgn}
\DeclareMathOperator{\sym}{Sym}
]]

local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local f = ls.function_node
local c = ls.choice_node
local i = ls.insert_node
local d = ls.dynamic_node
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep
local line_begin = require("luasnip.extras.expand_conditions").line_begin
local tex = require("util.latex")
local rec_ls
rec_ls = function()
  return sn(nil, {
    c(1, {
      -- important!! Having the sn(...) as the first choice will cause infinite recursion.
      t({ "" }),
      -- The same dynamicNode as in the snippet (also note: self reference).
      sn(nil, { t({ "", "\t\\item " }), i(1), d(2, rec_ls, {}) }),
    }),
  })
end

-- local get_visual = function(args, parent)
--   if #parent.snippet.env.SELECT_RAW > 0 then
--     return sn(nil, i(1, parent.snippet.env.SELECT_RAW))
--   else -- If SELECT_RAW is empty, return a blank insert node
--     return sn(nil, i(1))
--   end
-- end

return {
  s(
    { trig = "newfile", snippetType = "autosnippet" },
    fmta(
      [[
% !TeX program = xelatex
\documentclass[10pt]{<>}
\input{../preamble.tex}
\fancyhf{}
% ltex: enabled=false
% {{{ preamble
\fancypagestyle{plain}{
\lhead{<>}
\chead{\centering{<>}}
\rhead{\thepage\ of \pageref{LastPage}}
\lfoot{}
\cfoot{}
\rfoot{}}
\pagestyle{plain}
% ltex: enabled=true
% }}}

%-------------------basic info-------------------

\title{\textbf{<>}}
\author{Xinyu Xiang}
\date{<>. <>}

%-------------------document---------------------

\begin{document}
\maketitle

<>

\label{LastPage}
\end{document}
    ]],
      {
        i(1, "article"),
        i(2, "year"),
        i(3, "tietle"),
        rep(3),
        i(4, "month"),
        rep(2),
        i(0),
      }
    ),
    { condition = line_begin }
  ),

  s({ trig = "newpreamble", snippetType = "autosnippet" }, t(vim.split(preamble, "\n")), { condition = line_begin }),

  s(
    { trig = "root" },
    fmta([[ % !TeX root = ./<> ]], {
      i(0),
    }),
    { condition = line_begin }
  ),

  s(
    { trig = "nitem", wordTrig = true, snippetType = "autosnippet", trigEngine = "pattern" },
    fmta(
      [[
    \begin{itemize}
      \item <>
    \end{itemize}<>]],
      { i(1), i(0) }
    ),
    { condition = tex.in_itemize }
  ),

  s(
    { trig = "enum", wordTrig = true, snippetType = "autosnippet", trigEngine = "pattern" },
    fmta(
      [[
    \begin{enumerate}[(<>)]
      \item <>
    \end{enumerate}<>]],
      { i(1, "a"), i(2), i(0) }
    ),
    { condition = tex.in_itemize }
  ),

  s({ trig = "(mk|km)", snippetType = "autosnippet", trigEngine = "ecma" }, fmta([[$<>$<>]], { i(1), i(0) })),

  s(
    { trig = "%$(%w)", wordTrig = false, snippetType = "autosnippet", trigEngine = "pattern" },
    f(function(_, snip)
      return "$ " .. snip.captures[1]
    end),
    { condition = tex.in_text }
  ),

  s("list", {
    t({ "\\begin{itemize}", "\t\\item " }),
    i(1),
    d(2, rec_ls, {}),
    t({ "", "\\end{itemize}" }),
    i(0),
  }, { show_condition = tex.in_text }),

  s(
    { trig = "beg", snippetType = "autosnippet" },
    fmta(
      [[
      \begin{<>}
        <>
      \end{<>}<>]],
      {
        i(1),
        i(2),
        rep(1),
        i(0),
      }
    ),
    { condition = line_begin }
  ),

  s(
    { trig = "eqt", snippetType = "autosnippet" },
    fmta(
      [[
        \begin{equation}
          <>
        \end{equation}<>]],
      {
        i(1),
        i(0),
      }
    ),
    { condition = line_begin }
  ),

  s(
    { trig = "eqs", snippetType = "autosnippet" },
    fmta(
      [[
        \begin{equation*}
          <>
        \end{equation*}<>]],
      {
        i(1),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
  s(
    { trig = "defs", snippetType = "autosnippet" },
    fmta(
      [[
        \begin{definition}[<>]
          <>
        \end{definition}<>]],
      {
        i(1),
        i(2),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
}
