const prisma = require('./prisma');

// Create a post
const createPost = async (authorId, content, imageUrl = null) => {
  return prisma.post.create({
    data: {
      content,
      imageUrl,
      authorId: parseInt(authorId),
    },
    include: {
      author: {
        select: {
          id: true,
          name: true,
          username: true,
          profileImageUrl: true,
        },
      },
    },
  });
};

// Get a post by ID
const getPostById = async (id) => {
  return prisma.post.findUnique({
    where: { id: parseInt(id) },
    include: {
      author: {
        select: {
          id: true,
          name: true,
          username: true,
          profileImageUrl: true,
        },
      },
      _count: {
        select: {
          likes: true,
          comments: true,
        },
      },
    },
  });
};

// Get all posts by a user
const getPostsByUser = async (userId, page = 1, limit = 10) => {
  const skip = (page - 1) * limit;

  return prisma.post.findMany({
    where: { authorId: parseInt(userId) },
    include: {
      author: {
        select: {
          id: true,
          name: true,
          username: true,
          profileImageUrl: true,
        },
      },
      _count: {
        select: {
          likes: true,
          comments: true,
        },
      },
    },
    orderBy: { createdAt: 'desc' },
    skip,
    take: limit,
  });
};

// Like a post
const likePost = async (userId, postId) => {
  // Check if already liked
  const existingLike = await prisma.like.findFirst({
    where: {
      userId: parseInt(userId),
      postId: parseInt(postId),
    },
  });

  if (existingLike) {
    return { error: 'Post already liked' };
  }

  return prisma.like.create({
    data: {
      userId: parseInt(userId),
      postId: parseInt(postId),
    },
    include: {
      post: true,
    },
  });
};

// Unlike a post
const unlikePost = async (userId, postId) => {
  return prisma.like.deleteMany({
    where: {
      userId: parseInt(userId),
      postId: parseInt(postId),
    },
  });
};

// Check if a user has liked a post
const hasLiked = async (userId, postId) => {
  const like = await prisma.like.findFirst({
    where: {
      userId: parseInt(userId),
      postId: parseInt(postId),
    },
  });

  return !!like;
};

// Get all likes for a post
const getLikesByPost = async (postId) => {
  const likes = await prisma.like.findMany({
    where: { postId: parseInt(postId) },
    include: {
      user: {
        select: {
          id: true,
          name: true,
          username: true,
          profileImageUrl: true,
        },
      },
    },
    orderBy: { createdAt: 'desc' },
  });

  return likes.map(like => like.user);
};

// Add a comment to a post
const addComment = async (userId, postId, content) => {
  return prisma.comment.create({
    data: {
      content,
      userId: parseInt(userId),
      postId: parseInt(postId),
    },
    include: {
      user: {
        select: {
          id: true,
          name: true,
          username: true,
          profileImageUrl: true,
        },
      },
    },
  });
};

// Get all comments for a post
const getCommentsByPost = async (postId, page = 1, limit = 10) => {
  const skip = (page - 1) * limit;

  return prisma.comment.findMany({
    where: { postId: parseInt(postId) },
    include: {
      user: {
        select: {
          id: true,
          name: true,
          username: true,
          profileImageUrl: true,
        },
      },
    },
    orderBy: { createdAt: 'desc' },
    skip,
    take: limit,
  });
};

module.exports = {
  createPost,
  getPostById,
  getPostsByUser,
  likePost,
  unlikePost,
  hasLiked,
  getLikesByPost,
  addComment,
  getCommentsByPost,
}; 