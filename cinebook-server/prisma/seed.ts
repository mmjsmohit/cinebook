import { PrismaClient, Role, SeatCategory, ScreenType } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Clearing old data...');
  await prisma.message.deleteMany();
  await prisma.conversation.deleteMany();
  await prisma.adminActivityLog.deleteMany();
  await prisma.bookedSeat.deleteMany();
  await prisma.payment.deleteMany();
  await prisma.booking.deleteMany();
  await prisma.show.deleteMany();
  await prisma.seat.deleteMany();
  await prisma.screen.deleteMany();
  await prisma.theatre.deleteMany();
  await prisma.review.deleteMany();
  await prisma.movie.deleteMany();
  await prisma.genre.deleteMany();
  await prisma.user.deleteMany();
  await prisma.promoCode.deleteMany();

  console.log('Seeding Promo Codes...');
  await prisma.promoCode.createMany({
    data: [
      { code: 'WELCOME50', percentOff: 50 },
      { code: 'MOVIEBUFF20', percentOff: 20 },
      { code: 'FESTIVAL10', percentOff: 10 },
    ],
  });

  console.log('Seeding Users...');
  const customer = await prisma.user.create({
    data: {
      phone: '1111111111',
      name: 'Alice Customer',
      role: Role.CUSTOMER,
    },
  });

  const admin = await prisma.user.create({
    data: {
      phone: '2222222222',
      name: 'Bob Admin',
      role: Role.ADMIN,
    },
  });

  const manager = await prisma.user.create({
    data: {
      phone: '3333333333',
      name: 'Charlie Manager',
      role: Role.HALL_MANAGER,
    },
  });

  console.log('Seeding Genres...');
  const genres = ['Action', 'Sci-Fi', 'Drama', 'Comedy', 'Thriller'].map(name => ({ name }));
  for (const g of genres) {
    await prisma.genre.create({ data: g });
  }
  const allGenres = await prisma.genre.findMany();
  const getGenre = (name: string) => allGenres.find(g => g.name === name)!;

  console.log('Seeding Movies...');
  const moviesData = [
    {
      title: 'Inception',
      description: 'A thief who steals corporate secrets through the use of dream-sharing technology.',
      runtimeMin: 148,
      cast: ['Leonardo DiCaprio', 'Joseph Gordon-Levitt', 'Elliot Page'],
      posterUrl: 'https://example.com/inception.jpg',
      trailerUrl: 'https://youtube.com/watch?v=1',
      releaseDate: new Date('2010-07-16'),
      ageRating: 'UA',
      languages: ['English', 'Hindi'],
      genres: { connect: [{ id: getGenre('Sci-Fi').id }, { id: getGenre('Action').id }] }
    },
    {
      title: 'The Dark Knight',
      description: 'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham.',
      runtimeMin: 152,
      cast: ['Christian Bale', 'Heath Ledger', 'Aaron Eckhart'],
      posterUrl: 'https://example.com/tdk.jpg',
      trailerUrl: 'https://youtube.com/watch?v=2',
      releaseDate: new Date('2008-07-18'),
      ageRating: 'UA',
      languages: ['English'],
      genres: { connect: [{ id: getGenre('Action').id }, { id: getGenre('Thriller').id }] }
    },
    {
      title: 'Interstellar',
      description: 'A team of explorers travel through a wormhole in space in an attempt to ensure humanity\'s survival.',
      runtimeMin: 169,
      cast: ['Matthew McConaughey', 'Anne Hathaway', 'Jessica Chastain'],
      posterUrl: 'https://example.com/interstellar.jpg',
      trailerUrl: 'https://youtube.com/watch?v=3',
      releaseDate: new Date('2014-11-07'),
      ageRating: 'U',
      languages: ['English'],
      genres: { connect: [{ id: getGenre('Sci-Fi').id }, { id: getGenre('Drama').id }] }
    },
    {
      title: 'Parasite',
      description: 'Greed and class discrimination threaten the newly formed symbiotic relationship between the wealthy Park family and the destitute Kim clan.',
      runtimeMin: 132,
      cast: ['Song Kang-ho', 'Lee Sun-kyun', 'Cho Yeo-jeong'],
      posterUrl: 'https://example.com/parasite.jpg',
      trailerUrl: 'https://youtube.com/watch?v=4',
      releaseDate: new Date('2019-11-08'),
      ageRating: 'A',
      languages: ['Korean', 'English'],
      genres: { connect: [{ id: getGenre('Drama').id }, { id: getGenre('Thriller').id }] }
    },
    {
      title: 'Avatar',
      description: 'A paraplegic Marine dispatched to the moon Pandora on a unique mission becomes torn between following his orders and protecting the world he feels is his home.',
      runtimeMin: 162,
      cast: ['Sam Worthington', 'Zoe Saldana', 'Sigourney Weaver'],
      posterUrl: 'https://example.com/avatar.jpg',
      trailerUrl: 'https://youtube.com/watch?v=5',
      releaseDate: new Date('2009-12-18'),
      ageRating: 'UA',
      languages: ['English', 'Hindi', 'Tamil', 'Telugu'],
      genres: { connect: [{ id: getGenre('Sci-Fi').id }, { id: getGenre('Action').id }] }
    },
    {
      title: 'The Matrix',
      description: 'A computer hacker learns from mysterious rebels about the true nature of his reality and his role in the war against its controllers.',
      runtimeMin: 136,
      cast: ['Keanu Reeves', 'Laurence Fishburne', 'Carrie-Anne Moss'],
      posterUrl: 'https://example.com/matrix.jpg',
      trailerUrl: 'https://youtube.com/watch?v=6',
      releaseDate: new Date('1999-03-31'),
      ageRating: 'A',
      languages: ['English'],
      genres: { connect: [{ id: getGenre('Sci-Fi').id }, { id: getGenre('Action').id }] }
    },
  ];

  const movies = [];
  for (const movieData of moviesData) {
    const movie = await prisma.movie.create({
      data: movieData
    });
    movies.push(movie);
  }

  console.log('Seeding Reviews...');
  for (const movie of movies) {
    await prisma.review.create({
      data: {
        movieId: movie.id,
        rating: 9,
        author: 'Jane Critic',
        body: 'An absolute masterpiece!'
      }
    });
  }

  console.log('Seeding Theatres and Screens...');
  const chains = ['PVR', 'INOX', 'Cinepolis'];
  const screens = [];

  for (let i = 0; i < chains.length; i++) {
    const theatre = await prisma.theatre.create({
      data: {
        chain: chains[i],
        name: `${chains[i]} Cinemas, City Center`,
        city: 'Metropolis',
        address: `${100 + i} Main St, Metropolis`,
      }
    });

    for (let j = 1; j <= 3; j++) {
      const screen = await prisma.screen.create({
        data: {
          theatreId: theatre.id,
          name: `Screen ${j}`,
          type: j === 1 ? ScreenType.IMAX : ScreenType.STANDARD,
          format: j === 1 ? '3D' : '2D',
          equipment: ['Dolby Atmos', '4K Projection'],
          managerId: manager.id,
        }
      });
      screens.push(screen);

      // Seed Seats (Rows A-J, approx 10 rows)
      const seatRows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
      const seatsToCreate = [];
      for (const row of seatRows) {
        let category = SeatCategory.STANDARD;
        if (row === 'A' || row === 'B') category = SeatCategory.FRONT;
        else if (row === 'I' || row === 'J') category = SeatCategory.PREMIUM;
        
        // Let's add RECLINER for IMAX screens at the back
        if (screen.type === ScreenType.IMAX && row === 'J') category = SeatCategory.RECLINER;

        for (let num = 1; num <= 15; num++) {
          seatsToCreate.push({
            screenId: screen.id,
            row,
            number: num,
            category
          });
        }
      }
      await prisma.seat.createMany({ data: seatsToCreate });
    }
  }

  console.log('Seeding Shows...');
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  for (let dayOffset = 0; dayOffset < 7; dayOffset++) {
    const showDate = new Date(today);
    showDate.setDate(today.getDate() + dayOffset);

    // Add some shows for each screen
    for (const screen of screens) {
      // Pick a random movie
      const movie = movies[Math.floor(Math.random() * movies.length)];
      
      const showTimes = [
        { hour: 10, min: 0 },
        { hour: 14, min: 30 },
        { hour: 19, min: 0 },
        { hour: 22, min: 30 }
      ];

      for (const time of showTimes) {
        const startTime = new Date(showDate);
        startTime.setHours(time.hour, time.min, 0, 0);
        
        const endTime = new Date(startTime);
        endTime.setMinutes(startTime.getMinutes() + movie.runtimeMin + 30); // runtime + 30m break

        await prisma.show.create({
          data: {
            movieId: movie.id,
            screenId: screen.id,
            startTime,
            endTime,
            basePrice: 20000, // 200 INR
            language: movie.languages[0],
            format: screen.format,
          }
        });
      }
    }
  }

  console.log('Seeding finished successfully.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
