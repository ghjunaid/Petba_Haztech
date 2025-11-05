import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:petba_new/providers/Config.dart';

// Blog Model for List
class Blog {
  final int id;
  final String title;
  final int likeCount;
  final String img;
  final String dateTime;
  final String? subtitle;
  final String? description;
  final int? author;

  Blog({
    required this.id,
    required this.title,
    required this.likeCount,
    required this.img,
    required this.dateTime,
    this.subtitle,
    this.description,
    this.author,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      likeCount: json['like_count'] ?? 0,
      img: json['img'] ?? '',
      dateTime: json['date_time'] ?? '',
      subtitle: json['subtitle'],
      description: json['description'],
      author: json['author'],
    );
  }
}

// Blog Detail Model
class BlogDetail {
  final int id;
  final int authorId;
  int likeCount;
  final String img;
  final String title;
  final String subtitle;
  final String description;
  final String published;
  final String author;
  final String authImg;
  bool liked;

  BlogDetail({
    required this.id,
    required this.authorId,
    required this.likeCount,
    required this.img,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.published,
    required this.author,
    required this.authImg,
    required this.liked,
  });

  factory BlogDetail.fromJson(Map<String, dynamic> json) {
    return BlogDetail(
      id: json['id'] ?? 0,
      authorId: json['author_id'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      img: json['img'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      description: json['description'] ?? '',
      published: json['published'] ?? '',
      author: json['author'] ?? '',
      authImg: json['auth_img'] ?? '0',
      liked: json['liked'] == "true",
    );
  }
}

// Blog Comment Model - Updated to handle the correct field name
class BlogComment {
  final int id;
  final int blogId;
  final int fromId;
  final String comment;
  final String bTime;
  final String firstname;
  final String lastname;
  final String? img;

  BlogComment({
    required this.id,
    required this.blogId,
    required this.fromId,
    required this.comment,
    required this.bTime,
    required this.firstname,
    required this.lastname,
    this.img,
  });

  factory BlogComment.fromJson(Map<String, dynamic> json) {
    return BlogComment(
      id: json['id'] ?? 0,
      blogId: json['blog_id'] ?? 0,
      fromId: json['from_id'] ?? 0,
      comment: json['comment'] ?? '',
      bTime: json['b_time'] ?? '', // Use b_time as per API response
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      img: json['img'],
    );
  }

  String get fullName => '$firstname $lastname'.trim();
}
