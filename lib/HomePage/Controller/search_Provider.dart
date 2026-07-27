import 'dart:async';
import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/HomePage/Model/search_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GlobalSearchController extends GetxController {
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final LayerLink layerLink = LayerLink();

  var query = ''.obs;
  var results = <SearchResultItem>[].obs;
  var isLoading = false.obs;
  var isOverlayVisible = false.obs;

  Worker? _debounceWorker;

  @override
  void onInit() {
    super.onInit();
    _debounceWorker = debounce(
      query,
      (_) => _search(),
      time: const Duration(milliseconds: 400),
    );

    focusNode.addListener(() {
      if (focusNode.hasFocus && query.value.isNotEmpty) {
        isOverlayVisible.value = true;
      } else if (!focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          isOverlayVisible.value = false;
        });
      }
    });
  }

  // REPLACE _search() with:
  Future<void> _search() async {
    final q = query.value.trim();
    if (q.isEmpty) {
      results.clear();
      isOverlayVisible.value = false;
      return;
    }
    try {
      isLoading.value = true;
      isOverlayVisible.value = true;
      final url = ApiConfig.globalSearchUrl(q);
      debugPrint('[Search] hitting URL: $url');
      final data = await ApiService.globalSearch(q);
      debugPrint('[Search] got ${data.length} results');
      results.value = data;
      if (data.isEmpty) debugPrint('[Search] API returned empty products list');
    } catch (e) {
      debugPrint('[Search] error: $e');
      results.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void onChanged(String val) {
    query.value = val;
    if (val.isEmpty) {
      results.clear();
      isOverlayVisible.value = false;
    }
  }

  void clear() {
    textController.clear();
    query.value = '';
    results.clear();
    isOverlayVisible.value = false;
    focusNode.unfocus();
  }

  @override
  void onClose() {
    _debounceWorker?.dispose();
    textController.dispose();
    focusNode.dispose();
    super.onClose();
  }
}
