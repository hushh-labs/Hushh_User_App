import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_cost_logger.dart';

/// Service to process files using Gemini API for content extraction
class GeminiFileProcessorService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Extract content from a file using Gemini
  Future<Map<String, dynamic>?> extractFileContent({
    required String base64Data,
    required String mimeType,
    required String fileName,
  }) async {
    try {
      if (!isConfigured) {
        debugPrint('❌ [GEMINI] API key not configured');
        return null;
      }

      debugPrint('🔍 [GEMINI] Extracting content from $fileName ($mimeType)');

      // Prepare the request for Gemini
      final url =
          '$_baseUrl/models/gemini-1.5-pro:generateContent?key=$_apiKey';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': _getExtractionPrompt(fileName, mimeType)},
              {
                'inline_data': {'mime_type': mimeType, 'data': base64Data},
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.1,
          'topK': 32,
          'topP': 1,
          'maxOutputTokens': 8192,
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty) {
          final candidate = responseData['candidates'][0];
          final content = candidate['content'];
          final parts = content['parts'];

          if (parts != null && parts.isNotEmpty) {
            final extractedText = parts[0]['text'] as String;

            debugPrint(
              '✅ [GEMINI] Successfully extracted content from $fileName',
            );
            debugPrint(
              '📄 [GEMINI] Extracted ${extractedText.length} characters',
            );

            // Log cost information for this API call
            ApiCostLogger.logGeminiCost(
              prompt: _getExtractionPrompt(fileName, mimeType),
              response: extractedText,
              base64Data: base64Data,
              mimeType: mimeType,
              fileName: fileName,
            );

            return {
              'extractedText': extractedText,
              'fileName': fileName,
              'mimeType': mimeType,
              'extractedAt': DateTime.now().toIso8601String(),
              'extractionMethod': 'gemini',
              'success': true,
            };
          }
        }

        debugPrint('❌ [GEMINI] Invalid response format for $fileName');
        return null;
      } else {
        debugPrint(
          '❌ [GEMINI] API error ${response.statusCode}: ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ [GEMINI] Error extracting content from $fileName: $e');
      return null;
    }
  }

  /// Get extraction prompt based on file type
  String _getExtractionPrompt(String fileName, String mimeType) {
    if (mimeType.contains('pdf')) {
      return '''
EXTRACT EVERY SINGLE DETAIL from this PDF document. Leave nothing out. Provide an exhaustive analysis including:

1. **COMPLETE TEXT EXTRACTION**: 
   - Extract EVERY word, sentence, and paragraph from the document
   - Preserve exact formatting, spacing, and line breaks
   - Include ALL headers, subheaders, titles, and captions
   - Extract ALL footnotes, endnotes, and references
   - Include page numbers and any watermarks or stamps

2. **COMPREHENSIVE DOCUMENT STRUCTURE**:
   - Document title, author, creation date, modification date
   - Total number of pages and content on each page
   - Section divisions, chapters, and subsections
   - Paragraph numbering and bullet point hierarchies
   - Font styles, sizes, and formatting (bold, italic, underlined)

3. **EXHAUSTIVE DATA EXTRACTION**:
   - Extract EVERY table with ALL rows and columns
   - Include table headers, footers, and merged cells
   - Extract ALL numerical data, percentages, and calculations
   - Include ALL dates, times, and temporal references
   - Extract ALL names, addresses, phone numbers, emails
   - Include ALL monetary amounts, currencies, and financial data

4. **COMPLETE VISUAL ELEMENT ANALYSIS**:
   - Describe EVERY image, chart, graph, and diagram in detail
   - Extract data from ALL charts and graphs (exact values, labels, legends)
   - Describe ALL visual layouts, positioning, and spatial relationships
   - Include ALL logos, signatures, and graphical elements
   - Analyze ALL color schemes and visual formatting

5. **DETAILED METADATA AND PROPERTIES**:
   - Document properties, creation software, version information
   - Security settings, permissions, and restrictions
   - Language detection and character encoding
   - File size, compression, and technical specifications

6. **CONTEXTUAL ANALYSIS**:
   - Document purpose, intended audience, and context
   - Legal implications, contractual terms, and obligations
   - Key decisions, recommendations, and action items
   - Relationships between different sections and data points
   - Cross-references and internal document links

7. **COMPREHENSIVE CONTENT CATEGORIZATION**:
   - Classify ALL information by type (personal, financial, legal, technical)
   - Identify ALL entities (people, organizations, locations, products)
   - Extract ALL keywords, technical terms, and jargon
   - Categorize ALL data by importance and relevance

Extract EVERYTHING - no detail is too small. Provide the most comprehensive analysis possible.
''';
    } else if (mimeType.contains('csv') ||
        mimeType.contains('excel') ||
        mimeType.contains('spreadsheet')) {
      return '''
EXTRACT EVERY SINGLE PIECE OF DATA from this spreadsheet/CSV file. Provide an exhaustive analysis including:

1. **COMPLETE DATA STRUCTURE ANALYSIS**:
   - Exact number of rows and columns (including empty ones)
   - ALL column headers, subheaders, and merged header cells
   - Data types in EVERY column (text, number, date, formula, etc.)
   - Cell formatting (currency, percentage, date formats, etc.)
   - Hidden rows, columns, and sheets if any

2. **EXHAUSTIVE DATA EXTRACTION**:
   - Extract EVERY single cell value in the spreadsheet
   - Include ALL formulas and their calculated results
   - Extract ALL comments, notes, and cell annotations
   - Include ALL hyperlinks and external references
   - Extract data from ALL worksheets/tabs if multiple exist

3. **COMPREHENSIVE STATISTICAL ANALYSIS**:
   - Calculate totals, averages, min/max for ALL numerical columns
   - Identify ALL unique values in each column
   - Calculate frequency distributions and percentages
   - Identify ALL missing values, empty cells, and null entries
   - Analyze data ranges, outliers, and anomalies in EVERY column

4. **DETAILED PATTERN RECOGNITION**:
   - Identify ALL trends, patterns, and correlations in the data
   - Analyze seasonal patterns, growth rates, and changes over time
   - Identify ALL duplicate entries and data inconsistencies
   - Analyze relationships between different columns and data sets
   - Detect ALL data validation rules and constraints

5. **COMPLETE FORMATTING AND STRUCTURE**:
   - Document ALL cell formatting (colors, fonts, borders, alignment)
   - Extract ALL conditional formatting rules and their conditions
   - Include ALL chart data and graph information if embedded
   - Document ALL pivot table configurations and summaries
   - Extract ALL macro information and automated functions

6. **COMPREHENSIVE BUSINESS INTELLIGENCE**:
   - Identify ALL key performance indicators and metrics
   - Extract ALL financial data, budgets, and projections
   - Analyze ALL operational data and performance measures
   - Identify ALL business rules and logic embedded in the data
   - Extract ALL contact information, addresses, and personal data

7. **EXHAUSTIVE METADATA EXTRACTION**:
   - File creation date, modification history, and version information
   - Author information, last saved by, and editing history
   - Document properties, custom properties, and embedded metadata
   - Security settings, protection levels, and access permissions

Extract EVERY piece of data - leave no cell unanalyzed. Provide the most detailed data analysis possible.
''';
    } else if (mimeType.contains('word') || mimeType.contains('document')) {
      return '''
EXTRACT EVERY SINGLE DETAIL from this Word document. Provide an exhaustive analysis including:

1. **COMPLETE TEXT EXTRACTION**:
   - Extract EVERY word, sentence, and paragraph with exact formatting
   - Include ALL headers, footers, and page elements
   - Extract ALL footnotes, endnotes, comments, and tracked changes
   - Include ALL hyperlinks, bookmarks, and cross-references
   - Extract text from ALL text boxes, shapes, and embedded objects

2. **COMPREHENSIVE DOCUMENT STRUCTURE**:
   - Document title, author, creation date, and revision history
   - ALL section breaks, page breaks, and column breaks
   - Complete heading hierarchy and outline structure
   - ALL paragraph styles, character styles, and formatting
   - Page layout, margins, orientation, and paper size settings

3. **EXHAUSTIVE FORMATTING ANALYSIS**:
   - ALL font types, sizes, colors, and text effects
   - ALL paragraph alignment, spacing, and indentation
   - ALL bullet points, numbering, and list formatting
   - ALL table structures with complete cell content
   - ALL borders, shading, and visual formatting elements

4. **COMPLETE TABLE AND DATA EXTRACTION**:
   - Extract EVERY table with ALL rows, columns, and cell content
   - Include ALL table headers, merged cells, and nested tables
   - Extract ALL numerical data, calculations, and formulas
   - Include ALL table formatting and styling information
   - Analyze ALL data relationships within tables

5. **COMPREHENSIVE VISUAL ELEMENT ANALYSIS**:
   - Describe ALL images, charts, diagrams, and embedded objects
   - Extract ALL captions, alt text, and image metadata
   - Analyze ALL SmartArt, shapes, and drawing objects
   - Include ALL watermarks, backgrounds, and page elements
   - Extract data from ALL embedded charts and graphs

6. **DETAILED CONTENT CATEGORIZATION**:
   - Identify ALL document sections and their purposes
   - Extract ALL contact information, addresses, and personal data
   - Identify ALL dates, deadlines, and temporal references
   - Extract ALL financial information, amounts, and calculations
   - Categorize ALL legal terms, clauses, and obligations

7. **EXHAUSTIVE METADATA AND PROPERTIES**:
   - Document properties, custom properties, and hidden metadata
   - Revision history, editing time, and collaboration information
   - Security settings, permissions, and document protection
   - Language settings, proofing information, and spell check data
   - Template information and style sheet details

8. **COMPREHENSIVE CONTENT ANALYSIS**:
   - Document purpose, audience, and contextual information
   - Key themes, topics, and subject matter analysis
   - Important decisions, recommendations, and action items
   - Contractual terms, agreements, and legal implications
   - Cross-references and document relationships

Extract EVERYTHING - every formatting detail, every piece of content, every metadata element. Provide the most comprehensive document analysis possible.
''';
    } else if (mimeType.contains('image')) {
      return '''
EXTRACT EVERY SINGLE DETAIL from this image. Provide an exhaustive analysis including:

1. **COMPLETE VISUAL DESCRIPTION**:
   - Describe EVERY object, person, animal, and element visible
   - Include ALL colors, shades, gradients, and color relationships
   - Analyze ALL lighting, shadows, reflections, and visual effects
   - Describe ALL textures, patterns, and surface details
   - Include ALL spatial relationships and positioning

2. **EXHAUSTIVE TEXT EXTRACTION (OCR)**:
   - Extract EVERY piece of readable text, no matter how small
   - Include ALL fonts, text sizes, and formatting styles
   - Extract text from ALL signs, labels, documents, and displays
   - Include ALL handwritten text and annotations
   - Extract text from ALL logos, watermarks, and branded elements

3. **COMPREHENSIVE DATA ANALYSIS**:
   - Extract ALL numerical data from charts, graphs, and displays
   - Include ALL labels, legends, axes, and data points
   - Analyze ALL tables, spreadsheets, and structured data visible
   - Extract ALL percentages, statistics, and measurements
   - Include ALL dates, times, and temporal information

4. **DETAILED TECHNICAL ANALYSIS**:
   - Image resolution, dimensions, and quality assessment
   - Color depth, compression, and technical specifications
   - Identify camera settings, EXIF data if visible
   - Analyze image composition, framing, and perspective
   - Include ALL technical elements and digital artifacts

5. **EXHAUSTIVE CONTEXTUAL INFORMATION**:
   - Identify ALL locations, landmarks, and geographical features
   - Recognize ALL brands, logos, and commercial elements
   - Identify ALL people (if appropriate), clothing, and accessories
   - Analyze ALL architectural elements and structural details
   - Include ALL environmental and atmospheric conditions

6. **COMPREHENSIVE CONTENT CATEGORIZATION**:
   - Classify ALL elements by type (natural, artificial, human-made)
   - Identify ALL activities, actions, and behaviors depicted
   - Categorize ALL objects by function, purpose, and context
   - Analyze ALL emotional expressions and human interactions
   - Include ALL symbolic, cultural, and contextual meanings

7. **DETAILED QUALITY AND CONDITION ANALYSIS**:
   - Assess image clarity, focus, and visual quality
   - Identify ANY damage, wear, or deterioration visible
   - Analyze lighting conditions and photographic quality
   - Include ANY distortions, artifacts, or technical issues
   - Assess completeness and any cropped or missing elements

8. **EXHAUSTIVE METADATA EXTRACTION**:
   - Extract ALL visible timestamps, dates, and time information
   - Include ALL copyright notices, attribution, and ownership marks
   - Identify ALL source indicators and origin information
   - Extract ALL embedded codes, QR codes, and machine-readable data
   - Include ALL security features and authentication elements

Extract EVERYTHING visible - no detail is too small, no text too tiny, no element too insignificant. Provide the most comprehensive image analysis possible.
''';
    } else {
      return '''
EXTRACT EVERY SINGLE DETAIL from this file. Provide an exhaustive analysis including:

1. **COMPLETE CONTENT EXTRACTION**:
   - Extract EVERY piece of readable text and data from the file
   - Include ALL formatting, structure, and layout information
   - Extract ALL metadata, properties, and file characteristics
   - Include ALL embedded elements and linked content

2. **COMPREHENSIVE STRUCTURE ANALYSIS**:
   - Analyze the complete organization and hierarchy of content
   - Identify ALL sections, divisions, and content blocks
   - Extract ALL relationships between different parts of the file
   - Include ALL navigation elements and internal references

3. **EXHAUSTIVE DATA IDENTIFICATION**:
   - Identify and extract ALL numerical data and calculations
   - Include ALL dates, times, and temporal references
   - Extract ALL contact information and personal data
   - Include ALL financial information and monetary amounts

4. **DETAILED TECHNICAL ANALYSIS**:
   - File format, version, and technical specifications
   - Creation software, encoding, and compatibility information
   - Security settings, permissions, and access controls
   - Compression, optimization, and storage characteristics

5. **COMPREHENSIVE CONTENT CATEGORIZATION**:
   - Classify ALL content by type, importance, and relevance
   - Identify ALL entities (people, places, organizations, products)
   - Extract ALL keywords, terms, and specialized vocabulary
   - Categorize ALL information by subject matter and context

Extract EVERYTHING - provide the most detailed and comprehensive analysis possible for this file type.
''';
    }
  }

  /// Process multiple files in batch
  Future<List<Map<String, dynamic>>> processMultipleFiles(
    List<Map<String, dynamic>> files,
  ) async {
    final results = <Map<String, dynamic>>[];

    debugPrint(
      '🔍 [GEMINI] Processing ${files.length} files for content extraction',
    );

    for (final file in files) {
      final base64Data = file['base64Data'] as String?;
      final mimeType = file['mimeType'] as String?;
      final fileName = file['fileName'] as String?;

      if (base64Data != null && mimeType != null && fileName != null) {
        final result = await extractFileContent(
          base64Data: base64Data,
          mimeType: mimeType,
          fileName: fileName,
        );

        if (result != null) {
          results.add({...file, 'geminiExtraction': result});
        } else {
          results.add({
            ...file,
            'geminiExtraction': {
              'success': false,
              'error': 'Failed to extract content',
            },
          });
        }
      }
    }

    debugPrint('✅ [GEMINI] Completed processing ${results.length} files');
    return results;
  }

  /// Check if file type is supported by Gemini
  bool isFileTypeSupported(String mimeType) {
    final supportedTypes = [
      'application/pdf',
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
      'text/csv',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/plain',
    ];

    return supportedTypes.any((type) => mimeType.contains(type.split('/')[1]));
  }
}
