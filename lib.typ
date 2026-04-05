#let tromp(
  expression,
  use-labels: false,
  mode: "pixel",
  scale: 1.0,
) = {
  import "@preview/cetz:0.4.2": canvas, draw
  import "tromp.typ": tromp-recursion
  import "@preview/lambdabus:0.1.0" as lmd
  let parsed-expression = expression
  if type(parsed-expression) == str {
    parsed-expression = lmd.parse(parsed-expression)
  }
  if mode not in ("pixel", "line") {
    panic("unknown mode '" + mode + "'")
  }
  let result = tromp-recursion(parsed-expression, (), 0, 0, use-labels, do-label-movement: mode == "pixel")
  return canvas(length: 1cm * scale, {

    import draw: rect, line, content
    for (x1, y1, x2, y2, style) in result.lines {
      if style == auto {
        style = black
      }
      if mode == "pixel" {
        rect((x1, -0.5 * y1), (x2 + 0.25, -0.5 * y2 - 0.25), stroke: none, fill: style)
      } else if mode == "line" {
        line((x1, -0.5 * y1), (x2, -0.5 * y2), stroke: style)
      }
    }

    for (x, y, param, label) in result.labels {
      let label-content
      if type(label) == auto {
        label-content = $italic(param)$
      } else if type(label) == function {
        label-content = label(param)
      } else {
        label-content = label
      }
      if mode == "pixel" {
        content((x + 0.3, -0.5 * y - 0.225), text(label-content, 11pt * scale), anchor: "base-west")
      } else if mode == "line" {
        content((x + 0.125, -0.5 * y), text(label-content, 11pt * scale), anchor: "mid-west")
      }
    }
  })
}

#let expression(expression) = {
  import "@preview/lambdabus:0.1.0": lambda
  return lambda.tag(expression)
}

#let value(parameter, style: auto) = {
  return (
    type: "value",
    name: parameter,
    style: style,
  )
}

#let abstraction(parameter, body, style: auto, label: auto) = {
  import "@preview/lambdabus:0.1.0": parsing
  let parsed-body = body
  if type(parsed-body) == str {
    parsed-body = parsing.parse-expr(parsed-body.codepoints())
  }
  return (
    type: "abstraction",
    param: parameter,
    body: parsed-body,
    style: style,
    label: label,
  )
}

#let application(function, parameter, style: auto) = {
  import "@preview/lambdabus:0.1.0": parsing
  let parsed-function = function
  if type(parsed-function) == str {
    parsed-function = parsing.parse-expr(parsed-function.codepoints())
  }
  let parsed-parameter = parameter
  if type(parsed-parameter) == str {
    parsed-parameter = parsing.parse-expr(parsed-parameter.codepoints())
  }
  return (
    type: "application",
    fn: parsed-function,
    param: parsed-parameter,
    style: style,
  )
}
