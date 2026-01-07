// lib/core/ui/markdown_highlight_syntax.dart

import 'package:flutter_markdown/flutter_markdown.dart'; // <<< THIS IS THE CRITICAL FIX
import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;

/// A custom inline syntax parser for <mark> tags.
class HighlightSyntax extends md.InlineSyntax {
  HighlightSyntax() : super(r'<mark>(.+?)</mark>');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    // Create an 'mark' element with the text inside the tags.
    final element = md.Element.text('mark', match.group(1)!);
    parser.addNode(element);
    return true;
  }
}

/// A custom builder to render the 'mark' element.
class HighlightBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag == 'mark') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.4),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          element.textContent,
          style: preferredStyle?.copyWith(
            fontWeight: FontWeight.bold, // Make highlighted text bold
          ),
        ),
      );
    }
    // The super call was removed as it's not needed when returning null for unhandled cases.
    return null;
  }
}