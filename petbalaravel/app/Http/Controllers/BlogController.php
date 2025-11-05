<?php


namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BlogController
{
   public function bloglist(Request $request)
    {
        $data = json_decode($request->getContent());
        $c_id = $data->c_id ?? null;
        $type = $data->type ?? '0';

        try {
            $blogsQuery = DB::table('blog as b')
                ->select('b.id', 'b.title', 'b.like_count', 'b.img', 'b.date_time');

            if ($type === '1') {
                $blogsQuery->addSelect(
                        DB::raw('CONCAT(c.firstname, " ", c.lastname) as author'),
                        'c.img as auth_img'
                    )
                    ->join('oc_customer as c', 'b.author', '=', 'c.customer_id');
            }

            $blogs = $blogsQuery->get();

            return response()->json(['bloglist' => $blogs]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function blog(Request $request)
    {
        $data = json_decode($request->getContent());
        $id = $data->id;
        $c_id = $data->c_id;

        try {
            // Fetch the blog with author info
            $blog = DB::table('blog as b')
                ->select(
                    'b.id',
                    'b.author as author_id',
                    'b.like_count',
                    'b.img',
                    'b.title',
                    'b.subtitle',
                    'b.description',
                    'b.date_time as published',
                    DB::raw('CONCAT(c.firstname, " ", c.lastname) as author'),
                    'c.img as auth_img'
                )
                ->join('oc_customer as c', 'b.author', '=', 'c.customer_id')
                ->where('b.id', $id)
                ->first();

            if ($blog) {
                // Check if the blog is liked by the customer
                $liked = DB::table('blogLikeRelation')
                    ->where('blog_id', $id)
                    ->where('customer_id', $c_id)
                    ->value('liked') === 1;

                $blog->liked = $liked ? "true" : "false";
            }

            return response()->json(['blog' => $blog]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function BlogLiked(Request $request)
    {
        $data = json_decode($request->getContent());
        $c_id = $data->c_id;
        $blog_id = $data->blog_id;
        $liked = $data->liked;

        try {
            // Check if the like relation exists
            $exists = DB::table('blogLikeRelation')
                ->where('blog_id', $blog_id)
                ->where('customer_id', $c_id)
                ->exists();

            if (!$exists) {
                DB::table('blogLikeRelation')->insert([
                    'customer_id' => $c_id,
                    'blog_id' => $blog_id,
                    'liked' => $liked,
                ]);
            } else {
                DB::table('blogLikeRelation')
                    ->where('customer_id', $c_id)
                    ->where('blog_id', $blog_id)
                    ->update(['liked' => $liked]);
            }

            // Recalculate total likes for this blog
            $likeCount = DB::table('blogLikeRelation')
                ->where('blog_id', $blog_id)
                ->where('liked', 1)
                ->count();

            DB::table('blog')
                ->where('id', $blog_id)
                ->update(['like_count' => $likeCount]);

            return response()->json(['liked' => $liked == '1']);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function loadComment(Request $request)
    {
        $data = $request->json()->all();
        $id = $data['id'];
        $tag = $data['tag'];
        $lastPet = $data['offset'] ?? null;

        try {
            if ($tag === '0') {
                // Only return comment count
                $count = DB::table('rescue_comments')->where('rescue_id', $id)->count();
                return response()->json(['count' => $count]);
            }

            $query = DB::table('rescue_comments as R')
                ->leftjoin('oc_customer as C', 'R.from_id', '=', 'C.customer_id')
                ->where('R.rescue_id', $id)
                ->select('R.*', 'C.firstname', 'C.lastname')
                ->orderBy('R.c_time', 'asc');

            // Limit and pagination logic based on tag
            if ($tag === '4') {
                $query->limit(4);
            } elseif ($tag === '20') {
                $query->limit(20);
            } elseif ($tag === '5') {
                $query->limit(5);
                if ($lastPet !== null) {
                    $query->offset($lastPet);
                }
            }

            // For 'all' do not apply limit
            $comments = $query->get();

            return response()->json(['loadcomment' => $comments]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function loadBlogComment(Request $request)
    {
        $data = $request->json()->all();
        $id = $data['id'];
        $tag = $data['tag'];
        $offset = $data['next'] ?? null;

        try {
            if ($tag === '4') {
                $comments = DB::table('blog_comment as B')
                    ->leftjoin('oc_customer as C', 'B.from_id', '=', 'C.customer_id')
                    ->select('B.*', 'C.firstname', 'C.lastname', 'C.img')
                    ->where('B.blog_id', $id)
                    ->orderBy('B.b_time', 'ASC')
                    ->limit(4)
                    ->when($offset, function ($query, $offset) {
                        return $query->offset($offset);
                    })
                    ->get();
            } elseif ($tag === 'all') {
                $comments = DB::table('blog_comment as B')
                    ->join('oc_customer as C', 'B.from_id', '=', 'C.customer_id')
                    ->select('B.*', 'C.firstname', 'C.lastname', 'C.img')
                    ->where('B.blog_id', $id)
                    ->orderBy('B.b_time', 'ASC')
                    ->get();
            } elseif ($tag === '0') {
                $count = DB::table('blog_comment')
                    ->where('blog_id', $id)
                    ->count();

                return response()->json(['count' => $count]);
            } else {
                return response()->json(['error' => ['text' => 'Invalid tag provided']], 400);
            }

            return response()->json(['loadcomment' => $comments]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


   public function postBlogComment(Request $request)
{
    $data = $request->json()->all();

    $from_id = $data['c_id'];
    $blog_id = $data['blog_id'];
    $comment = $data['post'];
    $time    = $data['b_time'];

    try {
        // Insert comment
        $commentId = DB::table('blog_comment')->insertGetId([
            'from_id' => $from_id,
            'blog_id' => $blog_id,
            'comment' => $comment,
            'b_time'  => $time,
        ]);

        // Fetch comment with user details
        $commentData = DB::table('blog_comment as R')
            ->join('oc_customer as C', 'R.from_id', '=', 'C.customer_id')
            ->select('R.*', 'C.firstname', 'C.lastname', 'C.img')
            ->where('R.id', $commentId)
            ->first();

        // Send FCM notification
        sendFCM('blog', $blog_id, $from_id, $comment);

        return response()->json(['Post' => $commentData], 201);

    } catch (\Exception $e) {
        return response()->json([
            'error' => ['text' => $e->getMessage()]
        ], 500);
    }
}

    public function postComment(Request $request)
    {
        $data = $request->json()->all();
        $from_id = $data['c_id'];
        $rescue_id = $data['rescue_id'];
        $comment = $data['post'];
        $time = $data['c_time'];

        try {
            $commentId = DB::table('rescue_comments')->insertGetId([
                'from_id' => $from_id,
                'rescue_id' => $rescue_id,
                'comment' => $comment,
                'c_time' => $time,
            ]);

            $commentData = DB::select("SELECT R.*, C.firstname, C.lastname 
                                        FROM rescue_comments AS R 
                                        INNER JOIN oc_customer AS C ON R.from_id = C.customer_id 
                                        WHERE id = ?", [$commentId]);

            // Send FCM notification here (if needed)
            sendFCM('rescue_comment', $rescue_id, $from_id, $comment);

            return response()->json(['Post' => $commentData]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

   public function deleteComment(Request $request)
    {
        $data = $request->json()->all();
        $id = $data['id'];

        try {
            // Delete the comment with the given id
            DB::table('rescue_comments')->where('id', $id)->delete();

            return response()->json(['Post' => 'Deleted']);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function searchBlogs(Request $request)
    {
        $request->validate([
            'query' => 'required|string',
            'offset' => 'nullable|integer'
        ]);

        $query = $request->input('query');
        $offset = $request->input('offset', 0); // default to 0 if not provided

        try {
            $blogs = DB::table('blog as b')
                ->where('b.title', 'LIKE', '%' . $query . '%')
                ->orderByDesc('b.like_count')
                ->limit(10)
                ->offset($offset)
                ->get();

            return response()->json([
                'bloglist' => $blogs
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'error' => [
                    'text' => $e->getMessage()
                ]
            ], 500);
        }
    }


}
