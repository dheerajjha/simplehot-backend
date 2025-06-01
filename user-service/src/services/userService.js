const prisma = require('./prisma');

// Get user by ID
const getUserById = async (id) => {
  return prisma.user.findUnique({
    where: { id: parseInt(id) },
    select: {
      id: true,
      email: true,
      name: true,
      username: true,
      bio: true,
      profileImageUrl: true,
      coverImageUrl: true,
      createdAt: true,
      updatedAt: true,
      _count: {
        select: {
          followers: true,
          following: true,
          posts: true,
        },
      },
    },
  });
};

// Get user by email
const getUserByEmail = async (email) => {
  return prisma.user.findUnique({
    where: { email },
    select: {
      id: true,
      email: true,
      name: true,
      username: true,
      bio: true,
      profileImageUrl: true,
      coverImageUrl: true,
      createdAt: true,
      updatedAt: true,
      _count: {
        select: {
          followers: true,
          following: true,
          posts: true,
        },
      },
    },
  });
};

// Update user profile
const updateUser = async (id, data) => {
  return prisma.user.update({
    where: { id: parseInt(id) },
    data,
    select: {
      id: true,
      email: true,
      name: true,
      username: true,
      bio: true,
      profileImageUrl: true,
      coverImageUrl: true,
      createdAt: true,
      updatedAt: true,
    },
  });
};

// Get followers for a user
const getFollowers = async (userId) => {
  const follows = await prisma.follow.findMany({
    where: { followingId: parseInt(userId) },
    include: {
      follower: {
        select: {
          id: true,
          name: true,
          username: true,
          email: true,
          profileImageUrl: true,
          bio: true,
        },
      },
    },
    orderBy: { createdAt: 'desc' },
  });

  return follows.map(follow => follow.follower);
};

// Get users that a user is following
const getFollowing = async (userId) => {
  const follows = await prisma.follow.findMany({
    where: { followerId: parseInt(userId) },
    include: {
      following: {
        select: {
          id: true,
          name: true,
          username: true,
          email: true,
          profileImageUrl: true,
          bio: true,
        },
      },
    },
    orderBy: { createdAt: 'desc' },
  });

  return follows.map(follow => follow.following);
};

// Follow a user
const followUser = async (followerId, followingId) => {
  // Check if already following
  const existingFollow = await prisma.follow.findFirst({
    where: {
      followerId: parseInt(followerId),
      followingId: parseInt(followingId),
    },
  });

  if (existingFollow) {
    return { error: 'Already following this user' };
  }

  return prisma.follow.create({
    data: {
      followerId: parseInt(followerId),
      followingId: parseInt(followingId),
    },
    include: {
      following: true,
    },
  });
};

// Unfollow a user
const unfollowUser = async (followerId, followingId) => {
  return prisma.follow.deleteMany({
    where: {
      followerId: parseInt(followerId),
      followingId: parseInt(followingId),
    },
  });
};

// Check if a user is following another user
const isFollowing = async (followerId, followingId) => {
  const follow = await prisma.follow.findFirst({
    where: {
      followerId: parseInt(followerId),
      followingId: parseInt(followingId),
    },
  });

  return !!follow;
};

// Get posts from users that a user is following (feed)
const getFeed = async (userId, page = 1, limit = 10) => {
  const skip = (page - 1) * limit;

  // Get IDs of users that the current user is following
  const following = await prisma.follow.findMany({
    where: { followerId: parseInt(userId) },
    select: { followingId: true },
  });

  const followingIds = following.map(f => f.followingId);
  
  // Include the user's own posts in the feed
  followingIds.push(parseInt(userId));

  return prisma.post.findMany({
    where: {
      authorId: { in: followingIds },
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

module.exports = {
  getUserById,
  getUserByEmail,
  updateUser,
  getFollowers,
  getFollowing,
  followUser,
  unfollowUser,
  isFollowing,
  getFeed,
};