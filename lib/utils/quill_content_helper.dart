import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

/// Utilities to convert between Template.content (String) and Quill Delta JSON.
///
/// Template.content can be one of two formats:
///   1. **Delta JSON** – a JSON-encoded List of Quill operations (new WYSIWYG format).
///   2. **Plain text** – legacy format; may contain [campo.var] tags.
class QuillContentHelper {
  /// Returns true if [content] is already stored as Quill Delta JSON.
  static bool isDelta(String content) {
    final trimmed = content.trimLeft();
    return trimmed.startsWith('[{"insert"') ||
        trimmed.startsWith('[{"retain"');
  }

  /// Converts a Template.content string into a [QuillController].
  ///
  /// If it's already Delta JSON, parses it with [Document.fromJson].
  /// Otherwise wraps plain text (legacy) in a basic Quill Document.
  static QuillController controllerFromContent(String content) {
    if (isDelta(content)) {
      try {
        final list = jsonDecode(content) as List<dynamic>;
        final doc = Document.fromJson(list);
        return QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        // Fall through to plain-text path
      }
    }

    // Legacy plain text → wrap in Quill document
    final doc = Document();
    if (content.isNotEmpty) {
      doc.insert(0, content);
    }
    return QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  /// Serialises a [QuillController]'s document to a JSON string for storage.
  static String contentFromController(QuillController controller) {
    final deltaJson = controller.document.toDelta().toJson();
    return jsonEncode(deltaJson);
  }

  /// Returns a short human-readable plain-text preview (no markup) from content.
  /// Used for card subtitles in TemplatesPage.
  static String plainTextPreview(String content, {int maxLength = 120}) {
    String plain;
    if (isDelta(content)) {
      try {
        final list = jsonDecode(content) as List<dynamic>;
        final doc = Document.fromJson(list);
        plain = doc.toPlainText();
      } catch (_) {
        plain = content;
      }
    } else {
      plain = content;
    }
    // Strip template variable tags
    plain = plain.replaceAll(RegExp(r'\[[a-zA-Z0-9_\.]+\]'), '');
    plain = plain.replaceAll('\n', ' ').trim();
    if (plain.length > maxLength) {
      return '${plain.substring(0, maxLength)}...';
    }
    return plain;
  }

  /// Returns a [Document] for read-only preview rendering.
  static Document documentFromContent(String content) {
    if (isDelta(content)) {
      try {
        final list = jsonDecode(content) as List<dynamic>;
        return Document.fromJson(list);
      } catch (_) {}
    }
    final doc = Document();
    if (content.isNotEmpty) {
      doc.insert(0, content);
    }
    return doc;
  }

  /// Transforms plain text tags `[tag.name]` into formatted links for editing
  static Delta transformOnLoad(Delta source) {
    final delta = Delta();
    final RegExp tagRegex = RegExp(r'\[([a-zA-Z0-9_\.]+)\]');
    
    for (final op in source.toList()) {
      if (op.isInsert && op.data is String) {
        final text = op.data as String;
        int lastIndex = 0;
        for (final match in tagRegex.allMatches(text)) {
          final tagFull = match.group(0)!;
          final tagName = tagFull.replaceAll('[', '').replaceAll(']', '').split('.').last;
          if (match.start > lastIndex) {
            delta.insert(text.substring(lastIndex, match.start), op.attributes);
          }
          final newAttrs = Map<String, dynamic>.from(op.attributes ?? {});
          newAttrs['link'] = 'actium-tag:$tagFull';
          delta.insert(tagName, newAttrs);
          lastIndex = match.end;
        }
        if (lastIndex < text.length) {
          delta.insert(text.substring(lastIndex), op.attributes);
        }
      } else {
        delta.push(op);
      }
    }
    return delta;
  }

  /// Transforms formatted links back into plain text tags `[tag.name]` and serializes to JSON
  static String transformOnSave(Delta source) {
    final delta = Delta();
    for (final op in source.toList()) {
      if (op.isInsert && op.data is String) {
        final attrs = op.attributes;
        if (attrs != null && attrs['link'] != null && attrs['link'].toString().startsWith('actium-tag:')) {
          final tagCode = attrs['link'].toString().replaceFirst('actium-tag:', '');
          final newAttrs = Map<String, dynamic>.from(attrs);
          newAttrs.remove('link');
          delta.insert(tagCode, newAttrs.isEmpty ? null : newAttrs);
        } else {
          delta.insert(op.data, attrs);
        }
      } else {
        delta.push(op);
      }
    }
    return jsonEncode(delta.toJson());
  }

  /// Strips conditional markup (`<IF_KEY>…</IF_KEY>` and `<IF_NOT_KEY>…</IF_NOT_KEY>`)
  /// from a plain-text string, keeping the inner content (preview shows everything).
  static String _stripConditionalBlocks(String text) {
    // Known condition keys – extend this list as new conditions are added.
    const keys = [
      'ACOMPANANTE', 'FISCAL', 'VEHICULO', 'DETENIDO', 'COMISARIA',
      'MENOR', 'EXTRANJERO', 'HERIDO',
    ];
    String result = text;
    for (final key in keys) {
      // We'll use a regex that handles optional spaces and newlines
      result = result.replaceAll(RegExp('<\\s*IF_$key\\s*>', caseSensitive: false), '');
      result = result.replaceAll(RegExp('<\\s*/\\s*IF_$key\\s*>', caseSensitive: false), '');
      result = result.replaceAll(RegExp('<\\s*IF_NOT_$key\\s*>', caseSensitive: false), '');
      result = result.replaceAll(RegExp('<\\s*/\\s*IF_NOT_$key\\s*>', caseSensitive: false), '');
    }
    // Fallback generic strip (catches any remaining <IF_...> tags)
    result = result.replaceAll(RegExp(r'<\s*/?\s*IF_[A-Z0-9_]+\s*>', caseSensitive: false), '');
    return result;
  }

  /// Returns a [Document] for read-only printed preview rendering (replaces tags with blanks).
  static Document documentForPrintedPreview(String content) {
    final doc = documentFromContent(content);
    final source = doc.toDelta();
    final delta = Delta();
    final RegExp tagRegex = RegExp(r'\[([^\]]+)\]');

    for (final op in source.toList()) {
      if (op.isInsert && op.data is String) {
        // First remove any leftover <IF_...> markup so it never appears as visible text.
        final cleaned = _stripConditionalBlocks(op.data as String);
        int lastIndex = 0;
        for (final match in tagRegex.allMatches(cleaned)) {
          if (match.start > lastIndex) {
            delta.insert(cleaned.substring(lastIndex, match.start), op.attributes);
          }
          // Replace every [tag] placeholder with double underscores
          delta.insert('__', op.attributes);
          lastIndex = match.end;
        }
        if (lastIndex < cleaned.length) {
          delta.insert(cleaned.substring(lastIndex), op.attributes);
        }
      } else {
        delta.push(op);
      }
    }
    return Document.fromDelta(delta);
  }
}
