const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  // Clear existing data
  await prisma.like.deleteMany({});
  await prisma.comment.deleteMany({});
  await prisma.post.deleteMany({});
  await prisma.follow.deleteMany({});
  await prisma.user.deleteMany({});

  // Create some users
  const user1 = await prisma.user.create({
    data: {
      email: 'user@example.com',
      name: 'Test User',
      username: 'testuser',
      bio: 'I am a test user',
      profileImageUrl: 'https://via.placeholder.com/150',
    },
  });

  const user2 = await prisma.user.create({
    data: {
      email: 'admin@example.com',
      name: 'Admin User',
      username: 'adminuser',
      bio: 'I am an admin user',
      profileImageUrl: 'https://via.placeholder.com/150',
    },
  });

  const user3 = await prisma.user.create({
    data: {
      email: 'jane@example.com',
      name: 'Jane Doe',
      username: 'janedoe',
      bio: 'Hello, I am Jane',
      profileImageUrl: 'https://via.placeholder.com/150',
    },
  });

  // Create follow relationships
  await prisma.follow.create({
    data: {
      followerId: user1.id,
      followingId: user2.id,
    },
  });

  await prisma.follow.create({
    data: {
      followerId: user2.id,
      followingId: user3.id,
    },
  });

  await prisma.follow.create({
    data: {
      followerId: user3.id,
      followingId: user1.id,
    },
  });

  // Create some posts
  const post1 = await prisma.post.create({
    data: {
      content: 'Hello world! This is my first post.',
      authorId: user1.id,
    },
  });

  const post2 = await prisma.post.create({
    data: {
      content: 'I love coding with Node.js and Prisma!',
      authorId: user2.id,
    },
  });

  // Add likes
  await prisma.like.create({
    data: {
      userId: user2.id,
      postId: post1.id,
    },
  });

  await prisma.like.create({
    data: {
      userId: user3.id,
      postId: post1.id,
    },
  });

  // Add comments
  await prisma.comment.create({
    data: {
      content: 'Great post!',
      userId: user2.id,
      postId: post1.id,
    },
  });

  await prisma.comment.create({
    data: {
      content: 'I agree!',
      userId: user3.id,
      postId: post1.id,
    },
  });

  console.log('Database has been seeded');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  }); 