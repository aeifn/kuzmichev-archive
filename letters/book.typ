#import "/template/archive.typ": *

#show: book.with(title: "Письма")

#title-page(
  author: [Егор Кузьмичев],
  title: [Письма],
  subtitle: [с комментариями и справками о персоналиях],
  portrait: "/template/images/kuzmichev_oval.pdf",
  years: [1867–1933],
  city: [Москва],
  publisher: [Издательство Кузьмичевых],
)

#contents()

#include "letters.typ"

= Персоналии
#include "persons.typ"
