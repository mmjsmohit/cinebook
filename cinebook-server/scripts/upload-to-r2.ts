import { PrismaClient } from '@prisma/client';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import dotenv from 'dotenv';
import path from 'path';

// Load environment variables
dotenv.config();

const {
  R2_ACCOUNT_ID,
  R2_ACCESS_KEY_ID,
  R2_SECRET_ACCESS_KEY,
  R2_BUCKET_NAME,
  R2_DEV_URL,
} = process.env;

if (!R2_ACCOUNT_ID || !R2_ACCESS_KEY_ID || !R2_SECRET_ACCESS_KEY || !R2_BUCKET_NAME || !R2_DEV_URL) {
  console.error('❌ Missing required R2 environment variables in .env');
  process.exit(1);
}

const prisma = new PrismaClient();

const s3 = new S3Client({
  endpoint: `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: R2_ACCESS_KEY_ID!,
    secretAccessKey: R2_SECRET_ACCESS_KEY!,
  },
  region: 'auto',
});

// Map legacy TMDB paths to their new valid counterparts
const URL_REPLACEMENTS: Record<string, string> = {
  '/pB8BM7pdSpqUa3Q4J96C4l9zYv.jpg': '/fFkMxrBYnEBcEHotxTQwx2nAncy.jpg',
  '/rprTVDeNOSSMEGDEWe4ybdQbaDB.jpg': '/cdGVNiyUt289DgopWUdImNVVDaw.jpg',
  '/5OzirqBbplr1dvJNbPFDazVPkYC.jpg': '/14Vm3EtPdwsafZlqgtYSUeOYEoY.jpg',
  '/9cqNxx0GxF0bAY1BDZWNMGsggQy.jpg': '/iLWzJxatuwwMT76dtMuwh3FEp2X.jpg',
  '/lIv1QinFqz4dlp5U4lQ6HaiskOZ.jpg': '/dJxfXlhZw5DEhNRehCYRHhOeGPC.jpg',
  '/9O7gLzmreU0nGkIB6K3BsJbzvNv.jpg': '/u5hLebzUOBGbnPikIyxI1159lhc.jpg',
  '/dM2w364MScsjFf8pfMbaWUcWrR.jpg': '/AmyQTQsNxITitCM0Ya5l5bpYGpn.jpg',
  '/kyeqmMI6XoH8J99HkZt8W78vJ8v.jpg': '/fwmoeF44DXBk1tC30QFAiE0nwjT.jpg',
  '/aKuFiU82s5MJpGZmdXJ9yB1M42P.jpg': '/5NzxkdrNZ4RfAvD4Wi7uFFnqjLk.jpg',
  '/ty8T4vg8vKx3xn9xm0LQGsmgIl.jpg': '/d1zEEovHcID7Hyj4S0DSPe7akVs.jpg',
};

// Helper to download an image from a URL, automatically correcting outdated paths
async function downloadImage(url: string): Promise<{ buffer: Buffer; filename: string }> {
  let finalUrl = url;
  let filename = url.split('/').pop() || '';

  for (const [oldPath, newPath] of Object.entries(URL_REPLACEMENTS)) {
    if (url.endsWith(oldPath)) {
      finalUrl = url.replace(oldPath, newPath);
      filename = newPath.substring(1);
      console.log(`      🔄 Redirecting old TMDB path: ${oldPath} -> ${newPath}`);
      break;
    }
  }

  const response = await fetch(finalUrl);
  if (!response.ok) {
    throw new Error(`Failed to fetch image: ${finalUrl} (${response.statusText})`);
  }
  const arrayBuffer = await response.arrayBuffer();
  return { buffer: Buffer.from(arrayBuffer), filename };
}

// Helper to determine Content-Type
function getContentType(filename: string): string {
  const ext = path.extname(filename).toLowerCase();
  if (ext === '.png') return 'image/png';
  if (ext === '.gif') return 'image/gif';
  if (ext === '.webp') return 'image/webp';
  return 'image/jpeg';
}

async function uploadToR2(key: string, buffer: Buffer, contentType: string): Promise<string> {
  await s3.send(
    new PutObjectCommand({
      Bucket: R2_BUCKET_NAME!,
      Key: key,
      Body: buffer,
      ContentType: contentType,
    })
  );
  return `${R2_DEV_URL}/${key}`;
}

async function main() {
  console.log('🚀 Starting R2 upload migration...');

  // 1. Migrate Movie Posters
  const movies = await prisma.movie.findMany();
  console.log(`🎬 Found ${movies.length} movies to check.`);
  
  for (const movie of movies) {
    if (!movie.posterUrl) {
      console.log(`   ⏭️ Skipping "${movie.title}" (no poster URL)`);
      continue;
    }

    if (movie.posterUrl.includes(R2_DEV_URL!)) {
      console.log(`   ⏭️ Skipping "${movie.title}" (already on R2)`);
      continue;
    }

    try {
      console.log(`   📥 Downloading poster for "${movie.title}" from: ${movie.posterUrl}`);
      const { buffer, filename } = await downloadImage(movie.posterUrl);
      
      const key = `posters/${filename}`;
      const contentType = getContentType(filename);

      console.log(`   📤 Uploading to R2: ${key}`);
      const cdnUrl = await uploadToR2(key, buffer, contentType);

      console.log(`   💾 Updating DB record with new URL: ${cdnUrl}`);
      await prisma.movie.update({
        where: { id: movie.id },
        data: { posterUrl: cdnUrl },
      });
      console.log(`   ✅ Successfully migrated "${movie.title}"`);
    } catch (error) {
      console.error(`   ❌ Failed to migrate poster for "${movie.title}":`, error);
    }
  }

  // 2. Migrate Genre Images
  const genres = await prisma.genre.findMany();
  console.log(`\n🎭 Found ${genres.length} genres to check.`);

  for (const genre of genres) {
    if (!genre.imageUrl) {
      console.log(`   ⏭️ Skipping "${genre.name}" (no banner URL)`);
      continue;
    }

    if (genre.imageUrl.includes(R2_DEV_URL!)) {
      console.log(`   ⏭️ Skipping "${genre.name}" (already on R2)`);
      continue;
    }

    try {
      console.log(`   📥 Downloading banner for "${genre.name}" from: ${genre.imageUrl}`);
      const { buffer, filename } = await downloadImage(genre.imageUrl);

      const key = `genres/${filename}`;
      const contentType = getContentType(filename);

      console.log(`   📤 Uploading to R2: ${key}`);
      const cdnUrl = await uploadToR2(key, buffer, contentType);

      console.log(`   💾 Updating DB record with new URL: ${cdnUrl}`);
      await prisma.genre.update({
        where: { id: genre.id },
        data: { imageUrl: cdnUrl },
      });
      console.log(`   ✅ Successfully migrated genre "${genre.name}"`);
    } catch (error) {
      console.error(`   ❌ Failed to migrate banner for "${genre.name}":`, error);
    }
  }

  console.log('\n🎉 R2 upload migration completed!');
}

main()
  .catch((e) => {
    console.error('💥 Fatal error during migration:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
