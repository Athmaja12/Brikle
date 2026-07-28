import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/HomePage/Controller/search_Provider.dart';
import 'package:brikle/HomePage/Model/search_model.dart';
import 'package:brikle/Product/View/productdetails_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

bool _isValidUrl(String? url) {
  if (url == null || url.trim().isEmpty) return false;
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return false;
  if (!(uri.isScheme('HTTP') || uri.isScheme('HTTPS'))) return false;
  return uri.host.isNotEmpty;
}

class GlobalSearchBar extends StatefulWidget {
  const GlobalSearchBar({super.key});

  @override
  State<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends State<GlobalSearchBar> {
  // Anchors the field so the overlay entry can compute where to float
  // the results panel — this replaces the old CompositedTransformFollower
  // approach, which wasn't actually inserted into Flutter's real Overlay
  // and could get clipped/misplaced inside the scrolling CustomScrollView.
  final GlobalKey _fieldKey = GlobalKey();
  late final GlobalSearchController controller;
  OverlayEntry? _entry;
  Worker? _visibilityWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.find<GlobalSearchController>();
    _visibilityWorker = ever<bool>(controller.isOverlayVisible, (visible) {
      if (visible) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  void _showOverlay() {
    _removeOverlay();
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final width = renderBox.size.width;
    final height = renderBox.size.height;

    _entry = OverlayEntry(
      builder: (_) => Positioned(
        left: position.dx,
        top: position.dy + height + 4,
        width: width,
        child: const _SearchResultsPanel(),
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _visibilityWorker?.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _fieldKey,
      height: Responsive.height(context, 44),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, 12),
      ),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.textGray, size: 20),
          SizedBox(width: Responsive.space(context, 8)),
          Expanded(
            child: TextField(
              controller: controller.textController,
              focusNode: controller.focusNode,
              onChanged: controller.onChanged,
              style: AppTextStyles.loginSubtitle(
                context,
              ).copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search for products...",
                hintStyle: AppTextStyles.loginSubtitle(
                  context,
                ).copyWith(fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Obx(
            () => controller.query.value.isNotEmpty
                ? GestureDetector(
                    onTap: controller.clear,
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textGray,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── The actual floating results panel — now a real Overlay child, so it
// paints above every other widget on screen (carousel, categories, etc.)
// instead of being constrained/clipped by the scroll view's layout.
class _SearchResultsPanel extends StatelessWidget {
  const _SearchResultsPanel();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GlobalSearchController>();

    return Obx(() {
      return Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 360),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: controller.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              : controller.results.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.search_off, color: AppColors.textGray, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'No results for "${controller.query.value}"',
                        style: TextStyle(color: AppColors.textGray, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: controller.results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return _SearchResultTile(
                      item: controller.results[index],
                      onTap: () {
                        final result = controller.results[index];
                        controller.clear();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              product: CategoryProductItem(
                                variantId: result.variantId,
                                materialId: result.materialId,
                                name: result.productName,
                                imageUrl: result.masterImage ?? '',
                                price: double.tryParse(result.retailPrice) ?? 0,
                                brandName: result.brandName,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      );
    });
  }
}

class _SearchResultTile extends StatelessWidget {
  final SearchResultItem item;
  final VoidCallback onTap;
  const _SearchResultTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: _isValidUrl(item.masterImage)
                    ? Image.network(
                        item.masterImage!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.brandName,
                    style: TextStyle(fontSize: 11, color: AppColors.textGray),
                  ),
                  Text(
                    item.categoryName,
                    style: TextStyle(fontSize: 11, color: AppColors.textGray),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '₹${item.retailPrice}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFFF5F6FA),
    child: const Icon(
      Icons.inventory_2_outlined,
      color: Colors.black26,
      size: 24,
    ),
  );
}