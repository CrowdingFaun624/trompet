#import "lib.typ": *

// factorial
#tromp("\\n.\\f.n (\\f.\\n.n (f (\\f.\\x.n f (f x)))) (\\x.f) (\\x.x)", scale: 0.5)

// fibonacci
#tromp("\\n.\\f.n (\\c.\\a.\\b.c b (\\x.a (b x))) (\\x.\\y.x) (\\x.x) f", scale: 0.5)

#import "@preview/lambdabus:0.1.0": parse

#tromp(expression(application("\\n.\\f.n (\\f.\\n.n (f (\\f.\\x.n f (f x)))) (\\x.f) (\\x.x)", "\\f.\\x.f (f (f x))", style: red)), scale: 0.5)

#tromp(expression(
  abstraction("f", style: teal,
    abstraction("n", style: yellow,
      application(style: purple,
        value("f", style: orange),
        application(style: green,
          value("f", style: red),
          value("n", style: blue)
        )
      )
    ),
  )
))