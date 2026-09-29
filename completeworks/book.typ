#import "/template/archive.typ": *

#show: book.with(title: "Собрание сочинений")

#title-page(
  author: [Егор Кузьмичев],
  title: [Собрание сочинений],
  subtitle: [Стихотворения, рассказы, публицистика],
  portrait: "/template/images/kuzmichev_oval.pdf",
  years: [1867–1933],
  city: [Москва],
  publisher: [Издательство Кузьмичевых],
)

#contents()

= Стихотворения
#include "verses.typ"

= Рассказы
#include "stories.typ"

= Публицистика
#include "journalism.typ"
