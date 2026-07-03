import { prisma } from './src/db.js';

async function test() {
  try {
    const res = await prisma.genre.update({
      where: { id: 'cmr3olw1f0003pqbp1vj6a2pj' },
      data: { imageUrl: 'https://test.com/image.png' }
    });
    console.log(res);
  } catch (err) {
    console.error(err);
  }
}

test().finally(() => process.exit(0));
