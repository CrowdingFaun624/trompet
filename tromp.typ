#import "@preview/lambdabus:0.1.0" as lmd
#set page(height: auto)

#let recursive-thing(
  expression,
  abstractions,
  old-x,
  old-y,
  use-labels,
  is-base-abstraction: true,
  do-label-movement: true,
) = {
  // list of (x1, y1, x2, y2)
  let lines
  // labels of the abstractions
  let labels
  // (x-min, x-max) of each abstraction in scope (without the nubs)
  let abstraction-bounds
  // together, x and y specify the bottom-right corner that
  // applications must stretch over.
  let x = old-x
  let y = old-y

  if expression.type == "value" {
    labels = () // so we don't return labels: none
    let relevant-abstractions = abstractions.enumerate().filter(
      ((_, var)) => var == expression.name
    ).map(((index, _)) => index)
    if relevant-abstractions.len() == 0 {
      panic("variable " + expression.name + " is not in the expression")
    }
    // choose the last abstraction, since one could theoretically make them with duplicate names.
    let abstraction = relevant-abstractions.at(-1)
    // all abstractions in scope reach right
    abstraction-bounds = abstractions.map(
      _ => (x, x)
    )

    lines = ((x, abstraction, x, y),)
    // +1 so the next application will bend around this
    x += 1
  }

  else if expression.type == "abstraction" {
    let new-abstractions = abstractions
    new-abstractions.push(expression.param)
    let abstraction-y = y // height of abstraction line
    y += 1 // new abstraction was added, so future applications must bend over it.
    let body-result = recursive-thing(expression.body, new-abstractions, x, y, use-labels, is-base-abstraction: false, do-label-movement: do-label-movement)
    lines = body-result.lines
    labels = body-result.labels
    let new-abstraction-bounds = body-result.abstraction-bounds

    // don't return the just-added abstraction in abstraction-bounds
    abstraction-bounds = new-abstraction-bounds
    // mutate by popping to remove last item
    let (x-min, x-max) = abstraction-bounds.pop()
    lines.push((x-min - 0.25, abstraction-y, x-max + 0.25, abstraction-y))
    x = body-result.x
    y = body-result.y
    if use-labels {
      labels.push((x-max + 0.3, abstraction-y, expression.param))
      if is-base-abstraction and do-label-movement {
        x += 0.25
      }
    }
  }

  else if expression.type == "application" {
    let application-x1 = x
    let fn-result = recursive-thing(expression.fn, abstractions, x, y, use-labels, do-label-movement: do-label-movement)
    lines = fn-result.lines
    labels = fn-result.labels
    abstraction-bounds = fn-result.abstraction-bounds
    x = fn-result.x
    let fn-y = fn-result.y
    let application-x2 = x
    // use the old y because the parameter doesn't have to stretch over the function in the y-direction.
    let param-result = recursive-thing(expression.param, abstractions, x, y, use-labels, do-label-movement: do-label-movement)
    lines += param-result.lines
    labels += param-result.labels
    // expand abstractions to be widest of both
    abstraction-bounds = abstraction-bounds.zip(param-result.abstraction-bounds).map(
      (((x1-min, x1-max), (x2-min, x2-max))) => (calc.min(x1-min, x2-min), calc.max(x2-min, x2-max))
    )
    x = param-result.x
    let param-y = param-result.y
    y = calc.max(fn-y, param-y)
    lines.push((application-x1, y, application-x2, y))
    // line to parameter
    lines.push((application-x2, param-y, application-x2, y))
    y += 1
    // line to function
    lines.push((application-x1, fn-y, application-x1, y))
  }

  return (
    lines: lines,
    labels: labels,
    abstraction-bounds: abstraction-bounds,
    x: x,
    y: y,
  )
}

#let tromp(
  expression,
  use-labels: false,
  pixels: true,
  scale: 1.0,
) = {
  import "@preview/cetz:0.4.2": canvas, draw
  let parsed-expression = expression
  if type(parsed-expression) == str {
    parsed-expression = lmd.parse(parsed-expression)
  }
  let result = recursive-thing(parsed-expression, (), 0, 0, use-labels, do-label-movement: pixels)
  return canvas(length: 1cm * scale, {
    import draw: rect, line, content
    for (x1, y1, x2, y2) in result.lines {
      if pixels {
        rect((x1, -0.5 * y1), (x2 + 0.25, -0.5 * y2 - 0.25), stroke: none, fill: black)
      } else {
        line((x1, -0.5 * y1), (x2, -0.5 * y2))
      }
    }
    for (x, y, param) in result.labels {
      if pixels {
        content((x + 0.3, -0.5 * y - 0.225), text($italic(param)$, 11pt * scale), anchor: "base-west")
      } else {
        content((x + 0.125, -0.5 * y), text($italic(param)$, 11pt * scale), anchor: "mid-west")
      }
    }
  })
}

#lmd.parse("(\\x.x x) (\\x.x)")

#tromp("\\x.\\y.x x y")

#tromp("\\x.\\y.x y x")

#tromp("\\x.\\y.\\z.z (y x) (y z x) x")
#tromp("\\x.\\y.x (\\z.z) y")
#tromp("\\x.\\y.x (\\z.z z) (\\w.\\v.v (w w)) y")
#tromp("\\x.\\y.\\z.(x z) (y z)")
#tromp("\\n.\\f.n (\\c.\\a.\\b.c b (\\x.a (b x))) (\\x.\\y.x) (\\x.x) f", scale: 0.5, use-labels: false)
#tromp("(\\x.x x) (\\x.x x)")
