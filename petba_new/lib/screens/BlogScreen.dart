import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:petba_new/providers/Config.dart';
import 'package:petba_new/models/blog.dart';
import 'package:petba_new/services/user_data_service.dart';


// API Service
class BlogApiService {


  static Future<List<Blog>> fetchBlogs({String? customerId, String type = "0"}) async {
    try {
      // Use the provided customerId or default to "123" if null
      final cId = customerId ?? '';

      final response = await http.post(
        Uri.parse('$apiurl/api/bloglist'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'c_id': cId,
          'type': type,
        }),
      );

      print('Blog List Response status: ${response.statusCode}');
      print('Blog List Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> blogList = data['bloglist'] ?? [];

        return blogList.map((json) => Blog.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load blogs. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching blogs: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<List<Blog>> searchBlogs({required String query, int offset = 0}) async {
    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/searchblogs'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'query': query,
          'offset': offset,
        }),
      );

      print('Search Response status: ${response.statusCode}');
      print('Search Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> blogList = data['bloglist'] ?? [];

        return blogList.map((json) => Blog.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search blogs. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching blogs: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<BlogDetail> fetchBlogDetail({required int blogId, String? customerId}) async {
    try {
      // Use the provided customerId or default to "48" if null
      final cId = customerId ?? '';

      final response = await http.post(
        Uri.parse('$apiurl/api/blog'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'id': blogId.toString(),
          'c_id': cId,
        }),
      );

      print('Blog Detail Response status: ${response.statusCode}');
      print('Blog Detail Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final Map<String, dynamic> blogData = data['blog'];

        return BlogDetail.fromJson(blogData);
      } else {
        throw Exception('Failed to load blog detail. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching blog detail: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<bool> toggleBlogLike({
    required int blogId,
    required String customerId,
    required bool liked,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/blogliked'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'c_id': customerId,
          'blog_id': blogId,
          'liked': liked ? '1' : '0',
        }),
      );

      print('Like Response status: ${response.statusCode}');
      print('Like Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['liked'] ?? false;
      } else {
        throw Exception('Failed to update like status. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating like: $e');
      throw Exception('Network error: $e');
    }
  }

  // Updated method for loading blog comments - matches your API exactly
  static Future<List<BlogComment>> loadBlogComments({
    required int blogId,
    String tag = "4", // "4" for limited, "all" for all comments
    int? offset,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'id': blogId,
        'tag': tag,
      };

      // Only add 'next' if offset is provided and not for count requests
      if (offset != null && tag != '0') {
        requestBody['next'] = offset;
      }

      final response = await http.post(
        Uri.parse('$apiurl/api/loadblogcomment'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Comments Response status: ${response.statusCode}');
      print('Comments Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> commentList = data['loadcomment'] ?? [];

        return commentList.map((json) => BlogComment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load comments. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading comments: $e');
      throw Exception('Network error: $e');
    }
  }

  // Method for getting comment count
  static Future<int> getBlogCommentCount({required int blogId}) async {
    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/loadblogcomment'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'id': blogId,
          'tag': '0',
        }),
      );

      print('Comment Count Response status: ${response.statusCode}');
      print('Comment Count Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['count'] ?? 0;
      } else {
        throw Exception('Failed to load comment count. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading comment count: $e');
      throw Exception('Network error: $e');
    }
  }

  // Method for posting new comment
  static Future<BlogComment> postBlogComment({
    required int blogId,
    required String customerId,
    required String comment,
  }) async {
    try {
      final now = DateTime.now();
      final formattedTime = now.toIso8601String().substring(0, 19).replaceAll('T', ' ');

      final response = await http.post(
        Uri.parse('$apiurl/api/postblogcomment'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'c_id': int.parse(customerId),
          'blog_id': blogId,
          'post': comment,
          'b_time': formattedTime,
        }),
      );

      print('Post Comment Response status: ${response.statusCode}');
      print('Post Comment Response body: ${response.body}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final Map<String, dynamic> commentData = data['Post'];

        return BlogComment.fromJson(commentData);
      } else {
        throw Exception('Failed to post comment. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error posting comment: $e');
      throw Exception('Network error: $e');
    }
  }

  // Delete blog comment
  static Future<bool> deleteComment({required int commentId}) async {
    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/deletecomment'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'id': commentId,
        }),
      );

      print('Delete Comment Response status: ${response.statusCode}');
      print('Delete Comment Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['Post'] == 'Deleted';
      } else {
        throw Exception('Failed to delete comment. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting comment: $e');
      throw Exception('Network error: $e');
    }
  }
}

// Main Blog List Page
class BlogListPage extends StatefulWidget {
  @override
  _BlogListPageState createState() => _BlogListPageState();
}

class _BlogListPageState extends State<BlogListPage> {
  List<Blog> blogs = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  String? customerId; // Dynamic customer ID

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _fetchCustomerId();
    await loadBlogs();
  }

  Future<void> _fetchCustomerId() async {
    try {
      // Fetch customer ID like in your homepage
      final customerIdResult = await UserDataService.getCustomerId();
      setState(() {
        customerId = customerIdResult?.toString();
      });
      print('Retrieved customerId for blog list: $customerId');
    } catch (e) {
      print('Error fetching customer ID: $e');
      // Keep customerId as null, the API service will use default values
    }
  }

  Future<void> loadBlogs() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
      isSearching = false;
    });

    try {
      // Pass the dynamic customerId to the API service
      final fetchedBlogs = await BlogApiService.fetchBlogs(customerId: customerId);
      setState(() {
        blogs = fetchedBlogs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> searchBlogs(String query) async {
    if (query.trim().isEmpty) {
      loadBlogs();
      return;
    }

    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
      isSearching = true;
    });

    try {
      final searchResults = await BlogApiService.searchBlogs(query: query.trim());
      setState(() {
        blogs = searchResults;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
    }
  }

  void clearSearch() {
    searchController.clear();
    loadBlogs();
  }

  String formatDate(String dateTime) {
    try {
      DateTime parsedDate = DateTime.parse(dateTime);
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (e) {
      return dateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isSearching ? 'Search Results' : 'Pet Care Blogs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        actions: [
          if (isSearching)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.white),
              onPressed: clearSearch,
              tooltip: 'Clear search',
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _initializeData, // Changed to reinitialize data
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(70),
          child: Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onSubmitted: searchBlogs,
              decoration: InputDecoration(
                hintText: 'Search blogs...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.blue[600]),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    searchController.clear();
                    loadBlogs();
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
            SizedBox(height: 16),
            Text(
              'Loading blogs...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeData, // Changed to reinitialize data
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (blogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.article_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              isSearching ? 'No blogs found for "${searchController.text}"' : 'No blogs found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              isSearching ? 'Try searching with different keywords' : 'Check back later for new content',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            if (isSearching) ...[
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: clearSearch,
                icon: Icon(Icons.clear),
                label: Text('Clear Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _initializeData, // Changed to reinitialize data
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: blogs.length,
        itemBuilder: (context, index) {
          return BlogCard(
            blog: blogs[index],
            onTap: () {
              _showBlogDetails(blogs[index]);
            },
            formatDate: formatDate,
          );
        },
      ),
    );
  }

  void _showBlogDetails(Blog blog) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlogDetailPage(
          blogId: blog.id,
          customerId: customerId, // Pass the dynamic customer ID
        ),
      ),
    );
  }
}

// Blog Card Widget (unchanged)
class BlogCard extends StatelessWidget {
  final Blog blog;
  final VoidCallback onTap;
  final Function(String) formatDate;

  const BlogCard({
    Key? key,
    required this.blog,
    required this.onTap,
    required this.formatDate,
  }) : super(key: key);

  String stripHtmlTags(String htmlText) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(exp, '');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                height: 200,
                width: double.infinity,
                child: Image.asset(
                  '$apiurl/${blog.img}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pets,
                            size: 50,
                            color: Colors.grey[500],
                          ),
                          SizedBox(height: 8),
                          Text(
                            blog.img,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blog.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  if (blog.subtitle != null && blog.subtitle!.isNotEmpty) ...[
                    Text(
                      blog.subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                  ],
                  if (blog.description != null && blog.description!.isNotEmpty) ...[
                    Text(
                      stripHtmlTags(blog.description!),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 12),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 4),
                          Text(
                            formatDate(blog.dateTime),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: Colors.red[400],
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${blog.likeCount} likes',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Blog Detail Page with Dynamic Customer ID
class BlogDetailPage extends StatefulWidget {
  final int blogId;
  final String? customerId; // Accept customer ID as parameter

  const BlogDetailPage({
    Key? key,
    required this.blogId,
    this.customerId,
  }) : super(key: key);

  @override
  _BlogDetailPageState createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage> {
  BlogDetail? blogDetail;
  List<BlogComment> comments = [];
  int totalComments = 0;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  bool isLiking = false;
  bool isLoadingComments = false;
  bool showAllComments = false;
  bool isPostingComment = false;
  String? customerId; // Dynamic customer ID
  final TextEditingController commentController = TextEditingController();
  final FocusNode commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeCustomerId();
    loadBlogDetail();
    loadComments();
    loadCommentCount();
  }

  void _initializeCustomerId() {
    // Use the customer ID passed from the blog list page, or fetch it if not provided
    if (widget.customerId != null) {
      customerId = widget.customerId;
      print('Using passed customerId: $customerId');
    } else {
      _fetchCustomerId();
    }
  }

  Future<void> _fetchCustomerId() async {
    try {
      final customerIdResult = await UserDataService.getCustomerId();
      setState(() {
        customerId = customerIdResult?.toString() ?? "48"; // Default fallback
      });
      print('Retrieved customerId for blog detail: $customerId');
    } catch (e) {
      print('Error fetching customer ID: $e');
      setState(() {
        customerId = "48"; // Default fallback
      });
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> loadBlogDetail() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
    });

    try {
      // Use dynamic customer ID with fallback
      final detail = await BlogApiService.fetchBlogDetail(
          blogId: widget.blogId,
          customerId: customerId ?? "48"
      );
      setState(() {
        blogDetail = detail;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
    }
  }

  // Updated loadComments method to always sort comments (both limited and all)
  Future<void> loadComments({bool loadAll = false}) async {
    setState(() {
      isLoadingComments = true;
    });

    try {
      List<BlogComment> fetchedComments;

      if (loadAll) {
        // Get all comments
        fetchedComments = await BlogApiService.loadBlogComments(
          blogId: widget.blogId,
          tag: "all",
        );
      } else {
        // For limited comments, we need to get all and then take the latest 4
        // This ensures we always get the 4 most recent comments, not just the first 4
        final allComments = await BlogApiService.loadBlogComments(
          blogId: widget.blogId,
          tag: "all",
        );

        // Sort all comments by timestamp (newest first)
        allComments.sort((a, b) {
          try {
            DateTime dateA = DateTime.parse(a.bTime);
            DateTime dateB = DateTime.parse(b.bTime);
            return dateB.compareTo(dateA); // Newest first
          } catch (e) {
            print('Error parsing dates: $e');
            return b.id.compareTo(a.id); // Fallback to ID sorting
          }
        });

        // Take only the first 4 (which are the newest after sorting)
        fetchedComments = allComments.take(4).toList();
      }

      // Sort comments by timestamp (newest first) - this handles the "all" case
      fetchedComments.sort((a, b) {
        try {
          DateTime dateA = DateTime.parse(a.bTime);
          DateTime dateB = DateTime.parse(b.bTime);
          return dateB.compareTo(dateA); // Newest first
        } catch (e) {
          print('Error parsing dates: $e');
          return b.id.compareTo(a.id); // Fallback to ID sorting
        }
      });

      setState(() {
        comments = fetchedComments;
        showAllComments = loadAll;
        isLoadingComments = false;
      });
    } catch (e) {
      setState(() {
        isLoadingComments = false;
      });
      print('Error loading comments: $e');
    }
  }

  Future<void> loadCommentCount() async {
    try {
      final count = await BlogApiService.getBlogCommentCount(blogId: widget.blogId);
      setState(() {
        totalComments = count;
      });
    } catch (e) {
      print('Error loading comment count: $e');
    }
  }

  Future<void> postComment() async {
    if (commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a comment'),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User not authenticated. Please login again.'),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    setState(() {
      isPostingComment = true;
    });

    try {
      final newComment = await BlogApiService.postBlogComment(
        blogId: widget.blogId,
        customerId: customerId!,
        comment: commentController.text.trim(),
      );

      setState(() {
        commentController.clear();
        isPostingComment = false;
      });

      // Refresh comments and comment count
      await Future.wait([
        loadComments(loadAll: showAllComments),
        loadCommentCount(),
      ]);

      commentFocusNode.unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment posted successfully!'),
          backgroundColor: Colors.green[600],
          duration: Duration(seconds: 2),
        ),
      );

    } catch (e) {
      setState(() {
        isPostingComment = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post comment'),
          backgroundColor: Colors.red[600],
        ),
      );
      print('Error posting comment: $e');
    }
  }

  Future<void> deleteComment(BlogComment comment) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Comment'),
          content: Text('Are you sure you want to delete this comment? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final success = await BlogApiService.deleteComment(commentId: comment.id);

      if (success) {
        // Refresh comments and comment count
        await Future.wait([
          loadComments(loadAll: showAllComments),
          loadCommentCount(),
        ]);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comment deleted successfully'),
            backgroundColor: Colors.green[600],
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete comment'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting comment: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
      print('Error deleting comment: $e');
    }
  }

  Future<void> toggleLike() async {
    if (blogDetail == null || isLiking) return;

    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User not authenticated. Please login again.'),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    setState(() {
      isLiking = true;
    });

    try {
      final newLikedState = !blogDetail!.liked;
      final result = await BlogApiService.toggleBlogLike(
        blogId: widget.blogId,
        customerId: customerId!,
        liked: newLikedState,
      );

      setState(() {
        blogDetail!.liked = result;
        if (result) {
          blogDetail!.likeCount++;
        } else {
          blogDetail!.likeCount--;
        }
        isLiking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? 'Blog liked!' : 'Blog unliked!'),
          backgroundColor: result ? Colors.red[400] : Colors.grey[600],
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      setState(() {
        isLiking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update like status'),
          backgroundColor: Colors.red[600],
        ),
      );
      print('Error toggling like: $e');
    }
  }

  String formatDate(String dateTime) {
    try {
      DateTime parsedDate = DateTime.parse(dateTime);
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (e) {
      return dateTime;
    }
  }

  // Updated formatCommentDate method to handle ISO format from your API
  String formatCommentDate(String dateTime) {
    try {
      // Your API returns dates in ISO format like "2024-05-20T11:40:58.175Z"
      DateTime parsedDate = DateTime.parse(dateTime);
      DateTime now = DateTime.now();
      Duration difference = now.difference(parsedDate);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()}y ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}mo ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      print('Error formatting date: $dateTime, Error: $e');
      // Fallback: try to display the original date
      return dateTime.split('T')[0]; // Just show the date part
    }
  }

  String stripHtmlTags(String htmlText) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(exp, '');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Blog Details'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              ),
              SizedBox(height: 16),
              Text(
                'Loading blog details...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (hasError || blogDetail == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Blog Details'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              SizedBox(height: 16),
              Text(
                'Failed to load blog',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: loadBlogDetail,
                icon: Icon(Icons.refresh),
                label: Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                blogDetail!.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1.0, 1.0),
                      blurRadius: 3.0,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/${blogDetail!.img}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pets,
                              size: 80,
                              color: Colors.grey[500],
                            ),
                            SizedBox(height: 16),
                            Text(
                              blogDetail!.img,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            actions: [
              isLiking
                  ? Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
                  : IconButton(
                icon: Icon(
                  blogDetail!.liked ? Icons.favorite : Icons.favorite_border,
                  color: blogDetail!.liked ? Colors.red : Colors.white,
                ),
                onPressed: toggleLike,
                tooltip: blogDetail!.liked ? 'Unlike' : 'Like',
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    blogDetail!.title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      height: 1.3,
                    ),
                  ),

                  SizedBox(height: 8),

                  // Subtitle
                  if (blogDetail!.subtitle.isNotEmpty)
                    Text(
                      blogDetail!.subtitle,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),

                  SizedBox(height: 20),

                  // Author and Meta Information
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.blue[600],
                          child: blogDetail!.authImg != '0'
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.asset(
                              'assets/images/${blogDetail!.authImg}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.person, color: Colors.white, size: 25);
                              },
                            ),
                          )
                              : Icon(Icons.person, color: Colors.white, size: 25),
                        ),

                        SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'By ${blogDetail!.author}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Published on ${formatDate(blogDetail!.published)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Column(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Colors.red[400],
                              size: 20,
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${blogDetail!.likeCount}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // Content
                  Text(
                    'Content',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),

                  SizedBox(height: 16),

                  Text(
                    stripHtmlTags(blogDetail!.description),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.8,
                    ),
                  ),

                  SizedBox(height: 30),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isLiking ? null : toggleLike,
                          icon: isLiking
                              ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : Icon(blogDetail!.liked ? Icons.favorite : Icons.favorite_border),
                          label: Text(
                            isLiking
                                ? 'Updating...'
                                : (blogDetail!.liked ? 'Liked' : 'Like'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blogDetail!.liked ? Colors.red[400] : Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Share functionality coming soon!'),
                                backgroundColor: Colors.grey[600],
                              ),
                            );
                          },
                          icon: Icon(Icons.share),
                          label: Text('Share'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue[600],
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 40),

                  // Comments Section
                  Row(
                    children: [
                      Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalComments',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Comment Input Field
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add a comment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: commentController,
                          focusNode: commentFocusNode,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Share your thoughts about this blog...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                            ),
                            contentPadding: EdgeInsets.all(16),
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Be respectful and constructive',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: isPostingComment ? null : postComment,
                              child: isPostingComment
                                  ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Posting...'),
                                ],
                              )
                                  : Text('Post Comment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Comments List
                  if (isLoadingComments)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                        ),
                      ),
                    )
                  else if (comments.isEmpty)
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No comments yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Be the first to share your thoughts!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            return CommentCard(
                              comment: comments[index],
                              formatDate: formatCommentDate,
                              onDelete: () => deleteComment(comments[index]),
                              canDelete: comments[index].fromId.toString() == customerId,
                            );
                          },
                        ),

                        // Show More/Less Comments Button
                        if (totalComments > 4) ...[
                          SizedBox(height: 16),
                          Center(
                            child: OutlinedButton(
                              onPressed: () {
                                if (showAllComments) {
                                  loadComments(loadAll: false);
                                } else {
                                  loadComments(loadAll: true);
                                }
                              },
                              child: Text(
                                showAllComments
                                    ? 'Show Less Comments'
                                    : 'Show All Comments (${totalComments})',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue[600],
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Updated Comment Card Widget with Delete Functionality
class CommentCard extends StatelessWidget {
  final BlogComment comment;
  final String Function(String) formatDate;
  final VoidCallback? onDelete;
  final bool canDelete;

  const CommentCard({
    Key? key,
    required this.comment,
    required this.formatDate,
    this.onDelete,
    this.canDelete = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Row with Delete Button
          Row(
            children: [
              // User Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue[600],
                child: comment.img != null && comment.img!.isNotEmpty &&
                    comment.img != '0'
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/${comment.img}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        comment.fullName.isNotEmpty
                            ? comment.fullName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                )
                    : Text(
                  comment.fullName.isNotEmpty
                      ? comment.fullName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              SizedBox(width: 12),

              // User Name and Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.fullName.isNotEmpty
                          ? comment.fullName
                          : 'Anonymous User',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      formatDate(comment.bTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              // Delete Button (only show if user can delete this comment)
              if (canDelete && onDelete != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete!();
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                  [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red[600], size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: Colors.red[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
            ],
          ),

          SizedBox(height: 12),

          // Comment Text
          Text(
            comment.comment,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
