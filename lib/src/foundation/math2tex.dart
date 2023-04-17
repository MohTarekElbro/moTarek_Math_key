import 'dart:math' as math;

import 'package:math_expressions/math_expressions.dart' as math;
import 'package:math_keyboard/src/foundation/node.dart';

/// Converts the input [mathExpression] to a [TeXNode].
TeXNode convertMathExpressionToTeXNode(math.Expression mathExpression) {
  // The AST is not properly built (as in it is not well designed) because
  // nodes do not have a common super type. If they had, it would be easy to
  // convert the expression tree to a TeX tree. Like this we need two different
  // functions for handling "nodes" and bare "TeX".
  // todo: refactor AST.
  final node = TeXNode(null);
  node.children.addAll(_convertToTeX(mathExpression, node));
  return node;
}

List<TeX> _convertToTeX(math.Expression mathExpression, TeXNode parent) {
  print("addFunction: ${mathExpression.simplify().toString()}");
  if (mathExpression is math.UnaryOperator) {
    return [
      if (mathExpression is math.UnaryMinus)
        const TeXLeaf('-')
      else
        throw UnimplementedError(),
      ..._convertToTeX(mathExpression.exp, parent),
    ];
  }
  if (mathExpression is math.BinaryOperator) {
    List<TeX>? result;
    if (mathExpression is math.Divide) {
      result = [
        TeXFunction(
          r'\frac',
          parent,
          const [TeXArg.braces, TeXArg.braces],
          [
            convertMathExpressionToTeXNode(mathExpression.first),
            convertMathExpressionToTeXNode(mathExpression.second),
          ],
        ),
      ];
    } else if (mathExpression is math.Plus) {
      result = [
        ..._convertToTeX(mathExpression.first, parent),
        const TeXLeaf('+'),
        ..._convertToTeX(mathExpression.second, parent),
      ];
    } else if (mathExpression is math.Minus) {
      result = [
        ..._convertToTeX(mathExpression.first, parent),
        const TeXLeaf('-'),
        ..._convertToTeX(mathExpression.second, parent),
      ];
    } else if (mathExpression is math.Times) {
      result = [
        ..._convertToTeX(mathExpression.first, parent),
        const TeXLeaf(r'\cdot'),
        ..._convertToTeX(mathExpression.second, parent),
      ];
    } else if (mathExpression is math.Power) {
      result = [
        ..._convertToTeX(mathExpression.first, parent),
        TeXFunction(
          '^',
          parent,
          const [TeXArg.braces],
          [convertMathExpressionToTeXNode(mathExpression.second)],
        ),
      ];
    }
    if (result == null) {
      // Note that modulo is unsupported.
      throw UnimplementedError();
    }
    // Wrap with parentheses to keep precedence.
    return [
      TeXLeaf('('),
      ...result,
      TeXLeaf(')'),
    ];
  }
  if (mathExpression is math.Literal) {
    if (mathExpression is math.Number) {
      final number = mathExpression.value as double;
      if (number == math.pi) {
        return [TeXLeaf(r'{\pi}')];
      }
      if (number == math.e) {
        return [TeXLeaf('{e}')];
      }
      final adjusted = number.toInt() == number ? number.toInt() : number;
      return [
        for (final symbol in adjusted.toString().split('')) TeXLeaf(symbol),
      ];
    }
    if (mathExpression is math.Variable) {
      if (mathExpression is math.BoundVariable) {
        return [
          ..._convertToTeX(mathExpression.value, parent),
        ];
      }

      return [
        TeXLeaf('{${mathExpression.name}}'),
      ];
    }

    throw UnimplementedError();
  }
  if (mathExpression is math.DefaultFunction) {
    if (mathExpression is math.Exponential) {
      return [
        const TeXLeaf('{e}'),
        TeXFunction(
          '^',
          parent,
          const [TeXArg.braces],
          [convertMathExpressionToTeXNode(mathExpression.exp)],
        ),
      ];
    }
    if (mathExpression is math.Log) {
      return [
        TeXFunction(
          r'\log_',
          parent,
          const [TeXArg.braces, TeXArg.parentheses],
          [
            convertMathExpressionToTeXNode(mathExpression.base),
            convertMathExpressionToTeXNode(mathExpression.arg),
          ],
        ),
      ];
    }
    if (mathExpression is math.Ln) {
      return [
        const TeXLeaf(r'\ln('),
        ..._convertToTeX(mathExpression.arg, parent),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is math.Root) {
      if (mathExpression.n == 2) {
        return [
          TeXFunction(
            r'\sqrt',
            parent,
            const [TeXArg.braces],
            [convertMathExpressionToTeXNode(mathExpression.arg)],
          ),
        ];
      }
      return [
        TeXFunction(
          r'\sqrt',
          parent,
          const [TeXArg.brackets, TeXArg.braces],
          [
            convertMathExpressionToTeXNode(math.Number(mathExpression.n)),
            convertMathExpressionToTeXNode(mathExpression.arg),
          ],
        ),
      ];
    }
    if (mathExpression is math.Abs) {
      return [
        const TeXLeaf(r'\abs('),
        ..._convertToTeX(mathExpression.arg, parent),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is math.Sin) {
      return [
        const TeXLeaf(r'\sin('),
        ..._convertToTeX(mathExpression.arg, parent),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is math.Cos) {
      return [
        const TeXLeaf(r'\cos('),
        ..._convertToTeX(mathExpression.arg, parent),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is math.Tan) {
      return [
        const TeXLeaf(r'\tan('),
        ..._convertToTeX(mathExpression.arg, parent),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is math.Asin) {
      return [
        const TeXLeaf(r'\sin^{-1}('),
        ..._convertToTeX(mathExpression.arg, parent),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is math.Acos) {
      return [
        const TeXLeaf(r'\cos^{-1}('),
        ..._convertToTeX(mathExpression.arg, parent),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is math.Atan) {
      return [
        const TeXLeaf(r'\tan^{-1}('),
        ..._convertToTeX(mathExpression.arg, parent),
        const TeXLeaf(')'),
      ];
    }

    throw UnimplementedError();
  }

  throw UnimplementedError();
}
