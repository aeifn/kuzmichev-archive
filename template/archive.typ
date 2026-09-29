// Общее оформление архива Егора Кузьмичева.
//
// Книжный формат 145×205 мм (как у издания 2016 года), шрифт Old Standard TT —
// современная реконструкция «Обыкновенной новой» гарнитуры, которой набирали
// русские книги конца XIX — начала XX века, в том числе прижизненные издания
// Кузьмичева.

#let page-width = 145mm
#let page-height = 205mm
#let margins = (inside: 17mm, outside: 19mm, top: 20mm, bottom: 25mm)
#let body-height = page-height - margins.top - margins.bottom

#let font = "Old Standard TT"
#let body-size = 10.5pt
#let leading = 0.62em
#let ink = rgb("#1d1b19")
#let faded = rgb("#6b6560")

// Шаг отступа строки в стихах (\vin в пакете verse).
#let vgap = 1.5em

// Маркер дополнительного отступа строки стихотворения.
#let vin = metadata("vin")

// Колонтитулы выключаются на титуле, шмуцтитулах и т. п.
#let _plain-page = state("plain-page", ())

#let _letterspaced(body, size: 0.78em) = text(
  size: size,
  tracking: 0.12em,
  upper(body),
)

#let _ornament = align(center, box(width: 2.2cm, line(length: 100%, stroke: 0.4pt + faded)))

// ---------------------------------------------------------------- стихи

// Разбирает тело стихотворения на строфы и строки.
// Строки разделяются `\`, строфы — пустой строкой.
#let _parse-verse(body) = {
  let children = if body.func() == [].func() { body.children } else { (body,) }
  let stanzas = ()
  let stanza = ()
  let parts = ()
  let indent = 0
  for c in children + (parbreak(),) {
    let f = c.func()
    if f == linebreak or f == parbreak {
      if parts.len() > 0 {
        stanza.push((indent: indent, body: parts.join()))
      }
      parts = ()
      indent = 0
      if f == parbreak and stanza.len() > 0 {
        stanzas.push(stanza)
        stanza = ()
      }
    } else if f == metadata and c.value == "vin" {
      indent += 1
    } else if f == [ ].func() and parts.len() == 0 {
      // пробел в начале строки
    } else {
      parts.push(c)
    }
  }
  stanzas
}

// Отступ строки по образцу (pattern) или чередованию (alt), как в пакете verse.
#let _pattern-indent(k, alt, pattern, cycle) = {
  if alt { return calc.rem(k, 2) }
  if pattern == none or pattern.len() == 0 { return 0 }
  if k < pattern.len() { return pattern.at(k) }
  if cycle { return pattern.at(calc.rem(k, pattern.len())) }
  0
}

// Стихотворение.
//
// title       — заголовок; none — стихотворение без названия (* * *)
// toc         — строка для содержания (по умолчанию — заголовок)
// dedication  — посвящение или эпиграф
// source      — источник текста (рукопись, газета)
// alt         — чередовать отступы строк (окружение altverse)
// pattern     — образец отступов строк в строфе, например (0, 0, 1)
// cycle       — повторять образец по всей строфе (patverse*)
// date        — дата под стихотворением
// note        — примечание под стихотворением
// signature   — подпись
// outlined    — показывать ли в содержании
#let poem(
  title: none,
  toc: none,
  dedication: none,
  source: none,
  alt: false,
  pattern: none,
  cycle: false,
  date: none,
  note: none,
  signature: none,
  outlined: true,
  body,
) = {
  let stanzas = _parse-verse(body)
  let toc-entry = if toc != none { toc } else if title != none { title } else { [\* \* \*] }

  let lines = stanzas.map(stanza => stanza.enumerate().map(((k, l)) => (
    indent: l.indent + _pattern-indent(k, alt, pattern, cycle),
    body: l.body,
  )))

  let heading-block = block(sticky: true, above: 2.6em, below: 1.1em, width: 100%, {
    // скрытый заголовок: только для содержания и закладок PDF
    [#heading(level: 2, outlined: outlined, bookmarked: outlined, toc-entry) <toc-only>]
    set align(center)
    set par(justify: false, first-line-indent: 0pt)
    if title == none {
      text(size: 1.05em, tracking: 0.3em)[\*\*\*]
    } else {
      text(size: 1.2em, title)
    }
    if source != none {
      block(above: 0.7em, text(size: 0.82em, style: "italic", fill: faded, source))
    }
  })

  heading-block
  context {
    // ширина блока — по самой длинной строке, блок центрируется (\versewidth)
    let natural = calc.max(0pt, ..lines.flatten().map(l => measure(
      h(l.indent * vgap) + l.body,
    ).width))
    layout(size => {
      let width = calc.min(natural, size.width)
      let offset = (size.width - width) / 2
      // Строка — отдельный блок. «Липкие» строки не отрываются от следующих:
      // строфа не начинается и не заканчивается на странице меньше чем тремя строками.
      let render-line(l, k, n) = block(
        above: if k == 0 { 1.15em } else { leading },
        below: leading,
        sticky: k < 2 or (k >= n - 3 and k < n - 1),
        pad(left: offset + l.indent * vgap, par(hanging-indent: 2 * vgap, l.body)),
      )
      // Дата, подпись и посвящение выравниваются по правому краю стихотворения.
      let trailer(above: 1em, below: auto, body) = block(width: 100%, above: above, below: below, pad(
        right: offset,
        align(right, body),
      ))
      let content = {
        set par(first-line-indent: 0pt, justify: false)
        if dedication != none {
          trailer(above: 0pt, below: 1.4em, text(size: 0.85em, style: "italic", dedication))
        }
        for stanza in lines {
          for (k, l) in stanza.enumerate() { render-line(l, k, stanza.len()) }
        }
        if signature != none { trailer(text(size: 0.9em, signature)) }
        if date != none {
          trailer(above: if signature != none { 0.5em } else { 1em }, text(
            size: 0.85em,
            style: "italic",
            fill: faded,
            date,
          ))
        }
        if note != none {
          block(above: 0.9em, pad(left: offset, text(size: 0.85em, style: "italic", fill: faded, note)))
        }
      }
      // стихотворение, которое помещается на страницу, не разрывается
      let height = measure(block(width: size.width, content)).height
      block(width: 100%, breakable: height > 0.92 * body-height, content)
    })
  }
}

// ---------------------------------------------------------------- письма

// Дата письма (под заголовком); note — сноска к дате.
#let letter-date(note: none, body) = {
  [#metadata(body) <letter-date>]
  block(sticky: true, above: 0.5em, below: 0.4em, width: 100%, align(center, text(
    size: 0.92em,
    style: "italic",
    body + if note != none { footnote(note) },
  )))
}

// Архивный источник письма.
#let archive-source(body) = block(
  sticky: true,
  above: 0.4em,
  below: 1.4em,
  width: 100%,
  align(center, text(size: 0.8em, fill: faded, body)),
)

// Редакторское примечание между текстами.
#let editorial(body) = block(above: 2.4em, below: 1.2em, width: 100%, align(center, {
  _ornament
  v(0.4em)
  text(size: 0.88em, style: "italic", fill: faded, body)
}))

// ---------------------------------------------------------------- страницы

// Переход на правую страницу; пустая левая страница остается без колонтитулов.
#let _to-odd() = {
  [#metadata(none) <break-before>]
  pagebreak(weak: true, to: "odd")
  [#metadata(none) <break-after>]
}

// Пустая ли страница — вставлена ли она только ради перехода на нечетную.
#let _is-filler(p) = {
  let before = query(<break-before>)
  let after = query(<break-after>)
  for (b, a) in before.zip(after) {
    if a.location().page() == p + 1 and b.location().page() < p { return true }
  }
  false
}

#let _page-without-header() = context {
  let current = here().page()
  _plain-page.update(p => p + (current,))
}

// Титульный лист.
#let title-page(
  title: none,
  author: none,
  subtitle: none,
  portrait: none,
  years: none,
  city: none,
  publisher: none,
  year: none,
  verso: none,
) = {
  page(header: none, footer: none, {
  set align(center)
  set par(first-line-indent: 0pt, justify: false)
  v(1fr)
  if author != none { _letterspaced(author, size: 0.95em) }
  v(1.6em)
  text(size: 2.1em, title)
  if subtitle != none {
    v(0.5em)
    text(size: 1.05em, style: "italic", subtitle)
  }
  v(2.4em)
  if portrait != none {
    image(portrait, width: 44%)
  }
  if years != none {
    v(0.8em)
    text(size: 0.95em, tracking: 0.05em, years)
  }
  v(1.3fr)
  set text(size: 0.85em)
  if city != none { city; linebreak() }
  if publisher != none { publisher; linebreak() }
  if year != none { year }
  })
  // оборот титула
  page(header: none, footer: none, verso)
}

// Оборот титула: аннотация (передается в title-page как verso).
#let imprint(author: none, title: none, body) = {
  set par(first-line-indent: 0pt)
  v(1fr)
  set text(size: 0.85em)
  if author != none { strong(author) }
  if title != none {
    linebreak()
    title
  }
  v(0.8em)
  set par(first-line-indent: (amount: 1.2em, all: true), justify: true)
  body
  v(2fr)
}

// Фотография с подписью на отдельной странице.
#let photo(path, caption) = page(header: none, {
  set align(center + horizon)
  figure(
    image(path, width: 100%),
    caption: none,
    kind: "photo",
    supplement: none,
  )
  v(0.8em)
  block(width: 92%, {
    set par(justify: false, first-line-indent: 0pt)
    text(size: 0.85em, style: "italic", caption)
  })
})

// Содержание.
#let contents(title: [Содержание], depth: 2) = {
  _to-odd()
  _page-without-header()
  block(below: 2.4em, width: 100%, align(center, _letterspaced(title, size: 1.05em)))
  show outline.entry: it => {
    let loc = it.element.location()
    if it.level == 1 {
      block(above: 1.4em, below: 0.7em, link(loc, {
        set par(justify: false, first-line-indent: 0pt)
        _letterspaced(it.element.body, size: 0.82em)
        box(width: 1fr, repeat(gap: 0.3em)[.])
        text(size: 0.9em, str(loc.page()))
      }))
    } else {
      // у писем к заголовку добавляется дата
      let next = query(selector(heading).after(loc)).at(1, default: none)
      let dates = selector(<letter-date>).after(loc)
      if next != none { dates = dates.before(next.location(), inclusive: false) }
      let date = query(dates).first(default: none)
      block(above: 0.5em, below: 0.5em, link(loc, {
        set par(justify: false, first-line-indent: 0pt, hanging-indent: 1.2em)
        it.element.body
        if date != none {
          text(fill: faded)[, #date.value]
        }
        box(width: 1fr, repeat(gap: 0.3em)[.])
        h(0.3em)
        str(loc.page())
      }))
    }
  }
  set text(size: 0.92em)
  outline(title: none, depth: depth)
}

// ---------------------------------------------------------------- книга

#let book(title: none, author: [Егор Кузьмичев], running-title: none, body) = {
  set document(title: title, author: "Егор Кузьмичев")
  set text(font: font, size: body-size, lang: "ru", fill: ink, hyphenate: true)
  set par(
    justify: true,
    leading: leading,
    spacing: leading,
    first-line-indent: (amount: 1.2em, all: true),
  )
  set footnote.entry(separator: line(length: 25%, stroke: 0.4pt + faded), gap: 0.5em)
  show footnote.entry: set text(size: 0.82em)
  show footnote.entry: set par(first-line-indent: 0pt)

  let running = if running-title != none { running-title } else { title }

  set page(
    width: page-width,
    height: page-height,
    margin: margins,
    header-ascent: 45%,
    footer-descent: 40%,
    header: context {
      let p = here().page()
      if p in _plain-page.final() or _is-filler(p) { return }
      // на странице, где начинается раздел, колонтитула нет
      let starts = query(heading.where(level: 1)).filter(h => h.location().page() == p)
      if starts.len() > 0 { return }
      set text(size: 0.72em, tracking: 0.12em, fill: faded)
      if calc.even(p) {
        align(left, upper(author))
      } else {
        let parts = query(heading.where(level: 1).before(here()))
        let current = if parts.len() > 0 { parts.last().body } else { running }
        align(right, upper(current))
      }
    },
    footer: context {
      let p = here().page()
      if p in _plain-page.final() or _is-filler(p) { return }
      align(center, text(size: 0.85em, counter(page).display()))
    },
  )

  // Раздел (часть книги, период писем): отдельная страница справа.
  show heading.where(level: 1): it => {
    _to-odd()
    _page-without-header()
    v(24%)
    set align(center)
    set par(justify: false, first-line-indent: 0pt)
    _ornament
    v(1.4em)
    text(weight: "regular", _letterspaced(it.body, size: 1.35em))
    v(1.4em)
    _ornament
    pagebreak(weak: false)
  }

  // Заголовок текста (рассказ, статья, письмо).
  show heading.where(level: 2): it => {
    if it.has("label") and it.label == <toc-only> { return }
    block(sticky: true, above: 2.8em, below: 1.2em, width: 100%, {
      set align(center)
      set par(justify: false, first-line-indent: 0pt)
      text(size: 1.18em, weight: "regular", it.body)
    })
  }

  show heading.where(level: 3): it => block(sticky: true, above: 2em, below: 1em, width: 100%, {
    set align(center)
    set par(justify: false, first-line-indent: 0pt)
    text(size: 1em, style: "italic", weight: "regular", it.body)
  })

  body
}
