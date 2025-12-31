import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart'
    show NullabilitySuffix;
import 'package:analyzer/dart/element/type.dart'
    show DartType, ParameterizedType;
import 'package:jserializer_generator/src/resolved_type.dart';
import 'package:jserializer_generator/src/util.dart';
import 'package:path/path.dart' as p;

class TypeResolver {
  final List<LibraryElement> libs;
  final Uri? targetFile;

  TypeResolver(this.libs, this.targetFile);

  String? resolveImport(Element? element) {
    // return early if element is null or a core type
    if (element == null || _isCoreDartType(element)) {
      return null;
    }

    // Get the element's library URI directly
    final elementLib = element.library;
    if (elementLib == null || _isCoreDartType(elementLib)) {
      return null;
    }

    final libUri = elementLib.uri;
    return targetFile == null
        ? elementLib.identifier
        : _relative(
            libUri,
            targetFile!,
          );
  }

  String _relative(Uri fileUri, Uri to) {
    var libName = to.pathSegments.first;
    if ((to.scheme == 'package' &&
            fileUri.scheme == 'package' &&
            fileUri.pathSegments.first == libName) ||
        (to.scheme == 'asset' && fileUri.scheme != 'package')) {
      if (fileUri.path == to.path) {
        return fileUri.pathSegments.last;
      } else {
        return p.posix
            .relative(fileUri.path, from: to.path)
            .replaceFirst('../', '');
      }
    } else {
      return fileUri.toString();
    }
  }

  bool _isCoreDartType(Element element) {
    final library = element.library;
    return library != null && library.uri.toString() == 'dart:core';
  }

  List<ResolvedType> _resolveTypeArguments(DartType typeToCheck) {
    final importableTypes = <ResolvedType>[];
    if (typeToCheck is ParameterizedType) {
      for (DartType type in typeToCheck.typeArguments) {
        importableTypes.add(resolveType(type));
      }
    }
    return importableTypes;
  }

  ResolvedType resolveType(DartType type) {
    return ResolvedType(
      dartType: type,
      name: type.element?.name ?? type.getDisplayStringWithoutNullability(),
      isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
      import: resolveImport(type.element),
      typeArguments: _resolveTypeArguments(type),
    );
  }
}
