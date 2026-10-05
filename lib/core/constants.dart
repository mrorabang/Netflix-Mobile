import 'package:flutter/material.dart';

const kWidth = SizedBox(
  width: 10,
);
const kHeight = SizedBox(
  height: 10,
);
const kHeight20 = SizedBox(
  height: 20,
);

const kHeight50 = SizedBox(
  height: 50,
);

// border radius
final BorderRadius kRadius10 = BorderRadius.circular(10);
final BorderRadius kRadius30 = BorderRadius.circular(30);

// image
const mainImage =
    'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500';
const imageUrltemp1 =
    'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500';
const imageUrltemp2 =
    'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500';

// Textstyle
const TextStyle kHomeTitleText =
    TextStyle(fontSize: 14, fontWeight: FontWeight.bold);

const imageAppendUrl = "";
const mainScrenImage =
    'https://assets.nflxext.com/ffe/siteui/vlv3/ab180a27-b661-44d7-a6d9-940cb32f2f4a/7fb62e44-3180-4e2a-b9c2-b5e1c4a00bc9/VN-vi-20231009-popsignuptwoweeks-perspective_alpha_website_medium.jpg';

String resolveImageUrl(dynamic posterUrl, dynamic thumbUrl, [String? cdn]) {
  String raw = '';
  if (posterUrl is String && posterUrl.isNotEmpty) {
    raw = posterUrl;
  } else if (thumbUrl is String && thumbUrl.isNotEmpty) {
    raw = thumbUrl;
  }
  if (raw.isEmpty) {
    return 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500';
  }
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }
  final cdnUrl = (cdn != null && cdn.isNotEmpty)
      ? cdn
      : 'https://nguon.vsphim.com/storage/images/';
  final cleanCdn = cdnUrl.endsWith('/') ? cdnUrl : '$cdnUrl/';
  final cleanPath = raw.startsWith('/') ? raw.substring(1) : raw;
  return '$cleanCdn$cleanPath';
}
