import { PrismaClient, Role, SeatCategory, ScreenType } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Starting DB seed...');

  // 1. Create Users
  const customer = await prisma.user.upsert({
    where: { phone: '9999999991' },
    update: {},
    create: {
      phone: '9999999991',
      name: 'John Customer',
      role: Role.CUSTOMER,
    },
  });

  const hallManager = await prisma.user.upsert({
    where: { phone: '9999999992' },
    update: {},
    create: {
      phone: '9999999992',
      name: 'Manager Mike',
      role: Role.HALL_MANAGER,
    },
  });

  const admin = await prisma.user.upsert({
    where: { phone: '9999999993' },
    update: {},
    create: {
      phone: '9999999993',
      name: 'Admin Alice',
      role: Role.ADMIN,
    },
  });

  console.log('Users created.');

  // 2. Promo Codes
  await prisma.promoCode.upsert({
    where: { code: 'WELCOME50' },
    update: {},
    create: { code: 'WELCOME50', percentOff: 50, active: true },
  });
  await prisma.promoCode.upsert({
    where: { code: 'WEEKEND20' },
    update: {},
    create: { code: 'WEEKEND20', percentOff: 20, active: true },
  });

  console.log('Promo codes created.');

  // 3. Movies and Genres
  const genresData = ['Action', 'Comedy', 'Sci-Fi', 'Drama', 'Thriller', 'Animation'];
  const genres = await Promise.all(
    genresData.map(g =>
      prisma.genre.upsert({
        where: { name: g },
        update: {},
        create: { name: g },
      })
    )
  );

  const moviesData = [
    { title: 'Inception 2', description: 'Mind bending dream heist', runtimeMin: 140, ageRating: 'UA', releaseDate: new Date('2026-07-01') },
    { title: 'The Matrix Resurrected', description: 'Back to the matrix', runtimeMin: 130, ageRating: 'A', releaseDate: new Date('2026-06-15') },
    { title: 'Toy Story 5', description: 'Woody and Buzz again', runtimeMin: 95, ageRating: 'U', releaseDate: new Date('2026-07-10') },
    { title: 'Dune: Part Three', description: 'Sandworms and spice', runtimeMin: 160, ageRating: 'UA', releaseDate: new Date('2026-05-20') },
    { title: 'Avengers: Secret Wars', description: 'The ultimate battle', runtimeMin: 180, ageRating: 'UA', releaseDate: new Date('2026-05-01') },
    { title: 'Joker: Folie', description: 'Musical madness', runtimeMin: 120, ageRating: 'A', releaseDate: new Date('2026-08-01') },
    { title: 'Kung Fu Panda 5', description: 'Po returns', runtimeMin: 100, ageRating: 'U', releaseDate: new Date('2026-06-01') }
  ];

  const movies = [];
  for (const m of moviesData) {
    const movie = await prisma.movie.create({
      data: {
        ...m,
        cast: ['Actor 1', 'Actor 2'],
        languages: ['English', 'Hindi'],
        genres: {
          connect: [{ id: genres[0].id }]
        }
      }
    });
    movies.push(movie);

    // add a review
    await prisma.review.create({
      data: {
        movieId: movie.id,
        rating: 4,
        author: 'Reviewer Rick',
        body: 'Great movie, really enjoyed it!'
      }
    });
  }

  console.log('Movies and genres created.');

  // 4. Theatre Chains and Screens
  const chains = ['PVR', 'INOX', 'Cinepolis'];
  const rowBands = [
    { rows: ['A', 'B'], cat: SeatCategory.FRONT },
    { rows: ['C', 'D', 'E', 'F'], cat: SeatCategory.STANDARD },
    { rows: ['G', 'H', 'I'], cat: SeatCategory.PREMIUM },
    { rows: ['J'], cat: SeatCategory.RECLINER },
  ];

  for (let i = 0; i < chains.length; i++) {
    const theatre = await prisma.theatre.create({
      data: {
        chain: chains[i],
        name: `${chains[i]} Mall ${i}`,
        city: 'Metropolis',
        address: `${i} Main St, Metropolis`,
      }
    });

    const numScreens = 2 + (i % 2); // 2 to 3 screens
    for (let s = 1; s <= numScreens; s++) {
      const screen = await prisma.screen.create({
        data: {
          theatreId: theatre.id,
          name: `Screen ${s}`,
          type: s === 1 ? ScreenType.IMAX : ScreenType.STANDARD,
          format: s === 1 ? '3D' : '2D',
          equipment: ['Dolby Atmos', '4K Laser'],
          managerId: hallManager.id,
        }
      });

      // Create seats A-J
      const seatsToCreate = [];
      for (const band of rowBands) {
        for (const row of band.rows) {
          for (let n = 1; n <= 10; n++) {
            seatsToCreate.push({
              screenId: screen.id,
              row,
              number: n,
              category: band.cat
            });
          }
        }
      }
      await prisma.seat.createMany({ data: seatsToCreate });

      // Create shows for this screen for next 7 days
      const showsToCreate = [];
      for (let day = 0; day < 7; day++) {
        for (let hour of [10, 14, 18, 22]) {
          const d = new Date();
          d.setDate(d.getDate() + day);
          d.setHours(hour, 0, 0, 0);
          
          const dEnd = new Date(d);
          dEnd.setHours(d.getHours() + 2, 30, 0, 0);

          showsToCreate.push({
            movieId: movies[(s + day + hour) % movies.length].id, // pseudo-random movie
            screenId: screen.id,
            startTime: d,
            endTime: dEnd,
            basePrice: 20000, // 200 INR in paise
            language: 'English',
            format: '2D'
          });
        }
      }
      await prisma.show.createMany({ data: showsToCreate });
    }
  }

  console.log('Theatres, screens, seats, and shows created.');
  console.log('DB seed complete.');
}

main()
  .catch(e => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
