import { PrismaClient, Role, SeatCategory, ScreenType } from '@prisma/client';

const prisma = new PrismaClient();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
const tmdb = (path: string, type: 'posters' | 'genres' = 'posters') => {
  if (process.env.R2_ENABLED === 'true' && process.env.R2_DEV_URL) {
    return `${process.env.R2_DEV_URL}/${type}${path}`;
  }
  return `https://image.tmdb.org/t/p/w500${path}`;
};
const yt = (id: string) => `https://www.youtube.com/watch?v=${id}`;

// ---------------------------------------------------------------------------
// Genre definitions (imageUrl = a representative poster from that genre)
// ---------------------------------------------------------------------------
const GENRE_DATA = [
  { name: 'Action',    imageUrl: tmdb('/qJ2tW6WMUDux911r6m7haRef0WH.jpg', 'genres') }, // Dark Knight
  { name: 'Sci-Fi',   imageUrl: tmdb('/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg', 'genres') }, // Interstellar
  { name: 'Drama',    imageUrl: tmdb('/u5hLebzUOBGbnPikIyxI1159lhc.jpg', 'genres') }, // Shawshank
  { name: 'Comedy',   imageUrl: tmdb('/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg', 'genres') }, // Forrest Gump
  { name: 'Thriller', imageUrl: tmdb('/fFkMxrBYnEBcEHotxTQwx2nAncy.jpg', 'genres') }, // Fight Club
  { name: 'Crime',    imageUrl: tmdb('/AmyQTQsNxITitCM0Ya5l5bpYGpn.jpg', 'genres') }, // Pulp Fiction
  { name: 'Biography',imageUrl: tmdb('/dJxfXlhZw5DEhNRehCYRHhOeGPC.jpg', 'genres') }, // Whiplash
  { name: 'Adventure',imageUrl: tmdb('/fwmoeF44DXBk1tC30QFAiE0nwjT.jpg', 'genres') }, // Avatar
  { name: 'Romance',  imageUrl: tmdb('/14Vm3EtPdwsafZlqgtYSUeOYEoY.jpg', 'genres') }, // Walter Mitty
  { name: 'History',  imageUrl: tmdb('/sF1U4EUQS8YHUYjNl3pMGNIQyr0.jpg', 'genres') }, // Schindler's List
];

// ---------------------------------------------------------------------------
// Movie definitions
// ---------------------------------------------------------------------------
interface RawMovie {
  title: string;
  description: string;
  runtimeMin: number;
  cast: string[];
  posterUrl: string;
  trailerUrl: string;
  releaseDate: Date;
  ageRating: string;
  languages: string[];
  genreNames: string[];
  reviews: { author: string; rating: number; body: string }[];
}

const MOVIES: RawMovie[] = [
  // ─── USER-REQUESTED ───────────────────────────────────────────────────────
  {
    title: 'Fight Club',
    description: 'An insomniac office worker and a devil-may-care soap maker form an underground fight club that evolves into something much, much more sinister.',
    runtimeMin: 139,
    cast: ['Brad Pitt', 'Edward Norton', 'Helena Bonham Carter', 'Meat Loaf', 'Jared Leto'],
    posterUrl: tmdb('/fFkMxrBYnEBcEHotxTQwx2nAncy.jpg'),
    trailerUrl: yt('SUXWAEX2jlg'),
    releaseDate: new Date('1999-10-15'),
    ageRating: 'A',
    languages: ['English', 'Hindi'],
    genreNames: ['Drama', 'Thriller'],
    reviews: [
      { author: 'Roger Ebert', rating: 8, body: 'A stylish, subversive shock to the system.' },
      { author: 'Mark Kermode', rating: 9, body: 'Fincher at his most provocative and brilliant.' },
    ],
  },
  {
    title: 'Project Hail Mary',
    description: "Ryland Grace wakes alone on a spacecraft with no memory of who he is or how he got there. Piecing together his past, he realises he is humanity's last hope against an existential threat — and he's going to need some help.",
    runtimeMin: 140,
    cast: ['Ryan Gosling', 'Zach Galifianakis', 'Awkwafina'],
    posterUrl: tmdb('/cdGVNiyUt289DgopWUdImNVVDaw.jpg'),
    trailerUrl: yt('6Sj6-GZHEjg'),
    releaseDate: new Date('2026-03-20'),
    ageRating: 'UA',
    languages: ['English'],
    genreNames: ['Sci-Fi', 'Adventure', 'Drama'],
    reviews: [
      { author: 'The Guardian', rating: 9, body: 'A triumphant, tearjerking sci-fi adventure that stays true to the spirit of the novel.' },
      { author: 'Variety', rating: 9, body: 'Ryan Gosling is luminous. An unmissable cinematic event.' },
    ],
  },
  {
    title: 'The Secret Life of Walter Mitty',
    description: 'A day-dreamer escapes his anonymous life by disappearing into a world of fantasies. When his job is threatened, he takes action in the real world, embarking on a global journey more extraordinary than any fantasy.',
    runtimeMin: 114,
    cast: ['Ben Stiller', 'Kristen Wiig', 'Adam Scott', 'Shirley MacLaine', 'Sean Penn'],
    posterUrl: tmdb('/14Vm3EtPdwsafZlqgtYSUeOYEoY.jpg'),
    trailerUrl: yt('QD6cy4PBQPI'),
    releaseDate: new Date('2013-12-25'),
    ageRating: 'U',
    languages: ['English', 'Hindi'],
    genreNames: ['Adventure', 'Comedy', 'Drama', 'Romance'],
    reviews: [
      { author: 'Peter Bradshaw', rating: 8, body: 'A gorgeous, feel-good odyssey through Iceland, Greenland and the human spirit.' },
      { author: 'Empire', rating: 7, body: 'Visually stunning and quietly uplifting.' },
    ],
  },
  {
    title: 'The Matrix',
    description: 'A computer hacker learns from mysterious rebels about the true nature of his reality and his role in the war against its controllers. He is the One — and the machines know it.',
    runtimeMin: 136,
    cast: ['Keanu Reeves', 'Laurence Fishburne', 'Carrie-Anne Moss', 'Hugo Weaving', 'Joe Pantoliano'],
    posterUrl: tmdb('/iLWzJxatuwwMT76dtMuwh3FEp2X.jpg'),
    trailerUrl: yt('vKQi3bBA1y8'),
    releaseDate: new Date('1999-03-31'),
    ageRating: 'A',
    languages: ['English', 'Hindi', 'Tamil', 'Telugu'],
    genreNames: ['Sci-Fi', 'Action'],
    reviews: [
      { author: 'Roger Ebert', rating: 10, body: 'A film that redefines what science fiction can do on screen.' },
      { author: 'Total Film', rating: 9, body: 'A groundbreaking visual and philosophical masterpiece.' },
    ],
  },
  {
    title: 'Inception',
    description: 'A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O. — but only if he can navigate multiple layers of dreaming and outrun his own demons.',
    runtimeMin: 148,
    cast: ['Leonardo DiCaprio', 'Joseph Gordon-Levitt', 'Elliot Page', 'Tom Hardy', 'Ken Watanabe', 'Marion Cotillard'],
    posterUrl: tmdb('/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg'),
    trailerUrl: yt('YoHD9XEInc0'),
    releaseDate: new Date('2010-07-16'),
    ageRating: 'UA',
    languages: ['English', 'Hindi', 'Tamil', 'Telugu'],
    genreNames: ['Sci-Fi', 'Action', 'Thriller'],
    reviews: [
      { author: 'Empire', rating: 10, body: "The thinking person's blockbuster — and one of the decade's finest films." },
      { author: 'The Telegraph', rating: 9, body: "Nolan's magnum opus. A breathtaking puzzle of a movie." },
    ],
  },
  {
    title: 'Interstellar',
    description: "A team of explorers travel through a wormhole in space in an attempt to ensure humanity's survival. Cooper, a former NASA pilot, must leave his family behind and venture into the unknown — beyond our galaxy.",
    runtimeMin: 169,
    cast: ['Matthew McConaughey', 'Anne Hathaway', 'Jessica Chastain', 'Michael Caine', 'Matt Damon', 'Mackenzie Foy'],
    posterUrl: tmdb('/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg'),
    trailerUrl: yt('zSWdZVtXT7E'),
    releaseDate: new Date('2014-11-07'),
    ageRating: 'U',
    languages: ['English', 'Hindi'],
    genreNames: ['Sci-Fi', 'Adventure', 'Drama'],
    reviews: [
      { author: 'Mark Kermode', rating: 9, body: 'An awe-inspiring voyage into the cosmos and the human heart.' },
      { author: 'Variety', rating: 8, body: "Hans Zimmer's score and Hoyte van Hoytema's cinematography are worth the price of admission alone." },
    ],
  },
  {
    title: 'Whiplash',
    description: "A promising young drummer enrolls at a cut-throat music conservatory where his dreams of greatness are mentored by an instructor who will stop at nothing to realize a student's full potential.",
    runtimeMin: 107,
    cast: ['Miles Teller', 'J.K. Simmons', 'Melissa Benoist', 'Paul Reiser', 'Austin Stowell'],
    posterUrl: tmdb('/dJxfXlhZw5DEhNRehCYRHhOeGPC.jpg'),
    trailerUrl: yt('7d_jQycdQGo'),
    releaseDate: new Date('2014-10-10'),
    ageRating: 'UA',
    languages: ['English'],
    genreNames: ['Drama', 'Biography'],
    reviews: [
      { author: 'A.O. Scott', rating: 10, body: 'A ferocious and frightening film about art, ambition, and the abuse of power.' },
      { author: 'The Guardian', rating: 9, body: 'J.K. Simmons delivers one of the great screen villain performances.' },
    ],
  },

  // ─── CLASSICS ─────────────────────────────────────────────────────────────
  {
    title: 'The Dark Knight',
    description: 'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological and physical tests of his ability to fight injustice.',
    runtimeMin: 152,
    cast: ['Christian Bale', 'Heath Ledger', 'Aaron Eckhart', 'Michael Caine', 'Gary Oldman', 'Maggie Gyllenhaal'],
    posterUrl: tmdb('/qJ2tW6WMUDux911r6m7haRef0WH.jpg'),
    trailerUrl: yt('EXeTwQWrcwY'),
    releaseDate: new Date('2008-07-18'),
    ageRating: 'UA',
    languages: ['English', 'Hindi', 'Tamil', 'Telugu'],
    genreNames: ['Action', 'Thriller', 'Crime'],
    reviews: [
      { author: 'Roger Ebert', rating: 10, body: 'The Dark Knight is not a superhero movie — it is a crime film of operatic scope.' },
      { author: 'Empire', rating: 10, body: 'The greatest superhero movie ever made, and one of the greatest films ever made.' },
    ],
  },
  {
    title: 'The Shawshank Redemption',
    description: 'Two imprisoned men bond over a number of years, finding solace and eventual redemption through acts of common decency. Andy Dufresne serves time at Shawshank State Penitentiary, despite his claims of innocence.',
    runtimeMin: 142,
    cast: ['Tim Robbins', 'Morgan Freeman', 'Bob Gunton', 'William Sadler', 'Clancy Brown'],
    posterUrl: tmdb('/u5hLebzUOBGbnPikIyxI1159lhc.jpg'),
    trailerUrl: yt('6hB3S9bIaco'),
    releaseDate: new Date('1994-09-23'),
    ageRating: 'A',
    languages: ['English', 'Hindi'],
    genreNames: ['Drama', 'Crime'],
    reviews: [
      { author: 'Roger Ebert', rating: 10, body: "It's not a movie about prison, it's a movie about hope." },
      { author: 'The New Yorker', rating: 10, body: 'A timeless parable about the enduring power of friendship and the human spirit.' },
    ],
  },
  {
    title: 'The Godfather',
    description: 'The aging patriarch of an organized crime dynasty transfers control of his clandestine empire to his reluctant son. Spanning a decade, this is the definitive American crime saga.',
    runtimeMin: 175,
    cast: ['Marlon Brando', 'Al Pacino', 'James Caan', 'Diane Keaton', 'Robert Duvall', 'Talia Shire'],
    posterUrl: tmdb('/3bhkrj58Vtu7enYsRolD1fZdja1.jpg'),
    trailerUrl: yt('sY1S34973zA'),
    releaseDate: new Date('1972-03-24'),
    ageRating: 'A',
    languages: ['English', 'Hindi'],
    genreNames: ['Crime', 'Drama'],
    reviews: [
      { author: 'Pauline Kael', rating: 10, body: 'The greatest gangster film ever made and one of the greatest American films.' },
      { author: 'Empire', rating: 10, body: "Cinema doesn't get much better than this." },
    ],
  },
  {
    title: 'Pulp Fiction',
    description: 'The lives of two mob hitmen, a boxer, a gangster and his wife, and a pair of diner bandits intertwine in four tales of violence and redemption in Los Angeles. Non-linear, darkly comedic and irreverently brilliant.',
    runtimeMin: 154,
    cast: ['John Travolta', 'Uma Thurman', 'Samuel L. Jackson', 'Bruce Willis', 'Harvey Keitel', 'Tim Roth'],
    posterUrl: tmdb('/AmyQTQsNxITitCM0Ya5l5bpYGpn.jpg'),
    trailerUrl: yt('s7EdQ4FqbhY'),
    releaseDate: new Date('1994-10-14'),
    ageRating: 'A',
    languages: ['English'],
    genreNames: ['Crime', 'Thriller', 'Drama'],
    reviews: [
      { author: 'Roger Ebert', rating: 10, body: 'A glorious, free-wheeling masterpiece of American cinema.' },
      { author: 'Sight & Sound', rating: 10, body: 'Tarantino rewrote the rules of filmmaking with this astonishing film.' },
    ],
  },
  {
    title: 'Forrest Gump',
    description: 'The presidencies of Kennedy and Johnson, Vietnam, Watergate and other historical events unfold through the perspective of an Alabama man with an IQ of 75, whose only love is the girl he grew up with.',
    runtimeMin: 142,
    cast: ['Tom Hanks', 'Robin Wright', 'Gary Sinise', 'Mykelti Williamson', 'Sally Field'],
    posterUrl: tmdb('/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg'),
    trailerUrl: yt('bLvqoHBptjg'),
    releaseDate: new Date('1994-07-06'),
    ageRating: 'U',
    languages: ['English', 'Hindi', 'Tamil'],
    genreNames: ['Drama', 'Comedy', 'Romance'],
    reviews: [
      { author: 'Janet Maslin', rating: 9, body: 'A sweeping, warm-hearted American epic.' },
      { author: 'Rolling Stone', rating: 9, body: 'Tom Hanks at his absolute best — an irresistible film.' },
    ],
  },
  {
    title: "Schindler's List",
    description: 'In German-occupied Poland during World War II, industrialist Oskar Schindler gradually becomes concerned for his Jewish workforce after witnessing their persecution by the Nazis, and saves more than a thousand lives.',
    runtimeMin: 195,
    cast: ['Liam Neeson', 'Ben Kingsley', 'Ralph Fiennes', 'Caroline Goodall', 'Jonathan Sagall'],
    posterUrl: tmdb('/sF1U4EUQS8YHUYjNl3pMGNIQyr0.jpg'),
    trailerUrl: yt('mxphAlJID9U'),
    releaseDate: new Date('1993-12-15'),
    ageRating: 'A',
    languages: ['English', 'Hindi'],
    genreNames: ['History', 'Drama', 'Biography'],
    reviews: [
      { author: 'Roger Ebert', rating: 10, body: "This is Spielberg's masterpiece. A film that will endure as a testament to human evil and human goodness." },
      { author: 'Time', rating: 10, body: 'A monument to the power of cinema to bear witness.' },
    ],
  },
  {
    title: 'Parasite',
    description: 'Greed and class discrimination threaten the newly formed symbiotic relationship between the wealthy Park family and the destitute Kim clan. A Palme d\'Or winning masterwork of genre-blending cinema.',
    runtimeMin: 132,
    cast: ['Song Kang-ho', 'Lee Sun-kyun', 'Cho Yeo-jeong', 'Choi Woo-shik', 'Park So-dam', 'Jang Hye-jin'],
    posterUrl: tmdb('/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg'),
    trailerUrl: yt('5xH0HfJHsaY'),
    releaseDate: new Date('2019-11-08'),
    ageRating: 'A',
    languages: ['Korean', 'English'],
    genreNames: ['Thriller', 'Drama', 'Crime'],
    reviews: [
      { author: 'A.O. Scott', rating: 10, body: 'A perfectly calibrated masterwork from Bong Joon-ho.' },
      { author: 'Manohla Dargis', rating: 10, body: 'Flawless from its first frame to its last.' },
    ],
  },
  {
    title: 'Avatar',
    description: 'A paraplegic Marine dispatched to the moon Pandora on a unique mission becomes torn between following his orders and protecting the world he feels is his home.',
    runtimeMin: 162,
    cast: ['Sam Worthington', 'Zoe Saldana', 'Sigourney Weaver', 'Michelle Rodriguez', 'Stephen Lang', 'CCH Pounder'],
    posterUrl: tmdb('/fwmoeF44DXBk1tC30QFAiE0nwjT.jpg'),
    trailerUrl: yt('6ziBFh3V1aM'),
    releaseDate: new Date('2009-12-18'),
    ageRating: 'UA',
    languages: ['English', 'Hindi', 'Tamil', 'Telugu'],
    genreNames: ['Sci-Fi', 'Action', 'Adventure'],
    reviews: [
      { author: 'Roger Ebert', rating: 9, body: "Avatar is not just a movie — it's a technical wonder." },
      { author: 'Empire', rating: 8, body: 'James Cameron delivers the most visually spectacular film in cinema history.' },
    ],
  },
  {
    title: 'Goodfellas',
    description: 'The story of Henry Hill and his life in the mob, covering his steady rise, the treachery, the violence, the glamour and the brutal fall — and the federal protection that ultimately saved his life.',
    runtimeMin: 146,
    cast: ['Ray Liotta', 'Robert De Niro', 'Joe Pesci', 'Lorraine Bracco', 'Paul Sorvino'],
    posterUrl: tmdb('/5NzxkdrNZ4RfAvD4Wi7uFFnqjLk.jpg'),
    trailerUrl: yt('qo5jJpHtI1Y'),
    releaseDate: new Date('1990-09-19'),
    ageRating: 'A',
    languages: ['English'],
    genreNames: ['Crime', 'Drama', 'Biography'],
    reviews: [
      { author: 'Roger Ebert', rating: 10, body: 'The best mob movie ever made. Scorsese captures the seduction and the horror with breathtaking skill.' },
      { author: 'Pauline Kael', rating: 10, body: "A kinetic masterpiece. Scorsese's greatest film." },
    ],
  },
  {
    title: 'Gladiator',
    description: 'A former Roman General sets out to exact vengeance against the corrupt emperor who murdered his family and sent him into slavery. What begins as a fight for survival becomes a fight for the soul of Rome.',
    runtimeMin: 155,
    cast: ['Russell Crowe', 'Joaquin Phoenix', 'Connie Nielsen', 'Oliver Reed', 'Richard Harris', 'Derek Jacobi'],
    posterUrl: tmdb('/d1zEEovHcID7Hyj4S0DSPe7akVs.jpg'),
    trailerUrl: yt('owK1qxDselE'),
    releaseDate: new Date('2000-05-05'),
    ageRating: 'A',
    languages: ['English', 'Hindi'],
    genreNames: ['Action', 'Drama', 'Adventure', 'History'],
    reviews: [
      { author: 'Roger Ebert', rating: 8, body: 'A rousing, spectacular and surprisingly thoughtful epic.' },
      { author: 'Peter Travers', rating: 9, body: 'Ridley Scott crafts an action film that dares to ask serious questions.' },
    ],
  },
];

// ---------------------------------------------------------------------------
// Theatre / Screen specifications
// ---------------------------------------------------------------------------
interface TheatreSpec {
  chain: string;
  name: string;
  city: string;
  address: string;
  screens: { name: string; type: ScreenType; format: string; equipment: string[] }[];
}

const THEATRES: TheatreSpec[] = [
  {
    chain: 'PVR',
    name: 'PVR Cinemas, Phoenix Palassio',
    city: 'Lucknow',
    address: '2/1 Vibhuti Khand, Gomti Nagar, Lucknow – 226010',
    screens: [
      { name: 'Screen 1 – IMAX',     type: ScreenType.IMAX,        format: '3D', equipment: ['IMAX Laser', 'Dolby Atmos', '12-channel Surround'] },
      { name: 'Screen 2 – 4DX',      type: ScreenType.FOURDX,      format: '3D', equipment: ['4DX Motion Seats', 'Environmental Effects', 'Barco 4K'] },
      { name: 'Screen 3 – Standard', type: ScreenType.STANDARD,    format: '2D', equipment: ['Sony 4K Laser', 'Dolby Digital'] },
      { name: 'Screen 4 – Standard', type: ScreenType.STANDARD,    format: '2D', equipment: ['Sony 4K Laser', 'Dolby Digital'] },
    ],
  },
  {
    chain: 'INOX',
    name: 'INOX Leisure, Lulu Mall',
    city: 'Lucknow',
    address: 'Lulu Mall, Sushant Golf City, Lucknow – 226030',
    screens: [
      { name: 'Screen 1 – Dolby Atmos', type: ScreenType.DOLBY_ATMOS, format: '2D', equipment: ['Dolby Atmos', 'Barco 4K', 'Recliner Seating'] },
      { name: 'Screen 2 – Standard',    type: ScreenType.STANDARD,    format: '2D', equipment: ['Christie 4K', 'Dolby Digital'] },
      { name: 'Screen 3 – Standard',    type: ScreenType.STANDARD,    format: '2D', equipment: ['Christie 4K', 'DTS Sound'] },
    ],
  },
  {
    chain: 'Cinepolis',
    name: 'Cinepolis Fun Cinemas, Pacific Mall',
    city: 'Delhi',
    address: 'Pacific Mall, Subhash Nagar, New Delhi – 110027',
    screens: [
      { name: 'Screen 1 – VIP',      type: ScreenType.DOLBY_ATMOS, format: '3D', equipment: ['Dolby Atmos', 'Barco RGB Laser', 'VIP Recliners'] },
      { name: 'Screen 2 – IMAX',     type: ScreenType.IMAX,        format: '3D', equipment: ['IMAX Laser', 'IMAX Audio', '12-channel Sound'] },
      { name: 'Screen 3 – Standard', type: ScreenType.STANDARD,    format: '2D', equipment: ['NEC 4K', 'Dolby Digital Plus'] },
      { name: 'Screen 4 – Standard', type: ScreenType.STANDARD,    format: '2D', equipment: ['NEC 4K', 'Dolby Digital Plus'] },
    ],
  },
  {
    chain: 'PVR',
    name: 'PVR Icon, Orion Mall',
    city: 'Bengaluru',
    address: 'Orion Mall, Brigade Gateway, Malleshwaram, Bengaluru – 560055',
    screens: [
      { name: 'Screen 1 – Luxe',     type: ScreenType.DOLBY_ATMOS, format: '2D', equipment: ['Dolby Atmos', 'Recliner Seats', 'In-seat Dining'] },
      { name: 'Screen 2 – IMAX',     type: ScreenType.IMAX,        format: '3D', equipment: ['IMAX Laser', 'IMAX Certified Sound'] },
      { name: 'Screen 3 – Standard', type: ScreenType.STANDARD,    format: '2D', equipment: ['Sony 4K', 'Dolby Digital'] },
    ],
  },
  {
    chain: 'INOX',
    name: 'INOX Megaplex, R-City Mall',
    city: 'Mumbai',
    address: 'R-City Mall, LBS Road, Ghatkopar West, Mumbai – 400086',
    screens: [
      { name: 'Screen 1 – GTX',      type: ScreenType.IMAX,        format: '3D', equipment: ['GTX Large Format', 'Barco 4K Dual', 'Dolby Atmos'] },
      { name: 'Screen 2 – Sapphire', type: ScreenType.DOLBY_ATMOS, format: '2D', equipment: ['Dolby Atmos', 'Luxury Recliners', 'Christie 4K'] },
      { name: 'Screen 3 – Standard', type: ScreenType.STANDARD,    format: '2D', equipment: ['NEC 4K', 'DTS Sound'] },
      { name: 'Screen 4 – Standard', type: ScreenType.STANDARD,    format: '2D', equipment: ['NEC 4K', 'DTS Sound'] },
    ],
  },
];

// Base price per seat by screen type (stored in paise)
const BASE_PRICE: Record<ScreenType, number> = {
  [ScreenType.STANDARD]:    22000, // ₹220
  [ScreenType.DOLBY_ATMOS]: 30000, // ₹300
  [ScreenType.IMAX]:        40000, // ₹400
  [ScreenType.FOURDX]:      55000, // ₹550
};

const SHOW_TIMES = [
  { hour: 9,  min: 0  },
  { hour: 12, min: 0  },
  { hour: 15, min: 30 },
  { hour: 18, min: 45 },
  { hour: 22, min: 0  },
];

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
async function main() {
  console.log('🗑️  Clearing old data...');
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

  // ── Promo Codes ────────────────────────────────────────────────────────────
  console.log('🎟️  Seeding Promo Codes...');
  await prisma.promoCode.createMany({
    data: [
      { code: 'WELCOME50',     percentOff: 50, active: true },
      { code: 'MOVIEBUFF20',   percentOff: 20, active: true },
      { code: 'FESTIVAL10',    percentOff: 10, active: true },
      { code: 'FIRSTSHOW',     percentOff: 30, active: true },
      { code: 'IMAX15',        percentOff: 15, active: true },
      { code: 'BLOCKBUSTER25', percentOff: 25, active: true },
    ],
  });

  // ── Users ──────────────────────────────────────────────────────────────────
  console.log('👤  Seeding Users...');
  const customer = await prisma.user.create({
    data: {
      phone: '1111111111',
      name: 'Alice Customer',
      role: Role.CUSTOMER,
      prefs: {
        languages: ['English', 'Hindi'],
        seatCategory: 'PREMIUM',
        favouriteGenres: ['Sci-Fi', 'Thriller'],
      },
    },
  });

  await prisma.user.create({
    data: {
      phone: '1234567890',
      name: 'Raj Sharma',
      role: Role.CUSTOMER,
      prefs: {
        languages: ['Hindi', 'English'],
        seatCategory: 'STANDARD',
        favouriteGenres: ['Action', 'Crime'],
      },
    },
  });

  const admin = await prisma.user.create({
    data: {
      phone: '2222222222',
      name: 'Bob Admin',
      role: Role.ADMIN,
    },
  });

  const manager1 = await prisma.user.create({
    data: { phone: '3333333333', name: 'Charlie Manager', role: Role.HALL_MANAGER },
  });
  const manager2 = await prisma.user.create({
    data: { phone: '4444444444', name: 'Divya Manager', role: Role.HALL_MANAGER },
  });
  const manager3 = await prisma.user.create({
    data: { phone: '5555555555', name: 'Eshan Manager', role: Role.HALL_MANAGER },
  });
  const managers = [manager1, manager2, manager3];

  // ── Genres ─────────────────────────────────────────────────────────────────
  console.log('🎭  Seeding Genres...');
  for (const genreData of GENRE_DATA) {
    await prisma.genre.create({ data: genreData });
  }
  const allGenres = await prisma.genre.findMany();
  const getGenre = (name: string) => {
    const g = allGenres.find(g => g.name === name);
    if (!g) throw new Error(`Genre not found: ${name}`);
    return g;
  };

  // ── Movies & Reviews ───────────────────────────────────────────────────────
  console.log('🎬  Seeding Movies & Reviews...');
  const createdMovies = [];
  for (const m of MOVIES) {
    const { genreNames, reviews: reviewData, ...movieFields } = m;
    const movie = await prisma.movie.create({
      data: {
        ...movieFields,
        genres: { connect: genreNames.map(n => ({ id: getGenre(n).id })) },
      },
    });
    for (const r of reviewData) {
      await prisma.review.create({ data: { movieId: movie.id, ...r } });
    }
    createdMovies.push(movie);
    console.log(`   ✓ ${movie.title}`);
  }

  // ── Theatres, Screens & Seats ──────────────────────────────────────────────
  console.log('🏛️  Seeding Theatres, Screens & Seats...');
  const allScreens: { id: string; type: ScreenType; format: string }[] = [];
  let managerIdx = 0;

  for (const tSpec of THEATRES) {
    const theatre = await prisma.theatre.create({
      data: { chain: tSpec.chain, name: tSpec.name, city: tSpec.city, address: tSpec.address },
    });

    for (const sSpec of tSpec.screens) {
      const manager = managers[managerIdx % managers.length]!;
      managerIdx++;

      const screen = await prisma.screen.create({
        data: {
          theatreId: theatre.id,
          name: sSpec.name,
          type: sSpec.type,
          format: sSpec.format,
          equipment: sSpec.equipment,
          managerId: manager.id,
        },
      });

      // Seat layout
      const isLuxe = sSpec.type === ScreenType.IMAX || sSpec.type === ScreenType.FOURDX;
      const rows = isLuxe
        ? ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L']
        : ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
      const seatsPerRow = isLuxe ? 18 : 15;

      const seatsToCreate = [];
      for (const row of rows) {
        const rowIdx = rows.indexOf(row);
        let category: SeatCategory;
        if (rowIdx <= 1) {
          category = SeatCategory.FRONT;
        } else if (rowIdx >= rows.length - 2) {
          category =
            sSpec.type !== ScreenType.STANDARD
              ? SeatCategory.RECLINER
              : SeatCategory.PREMIUM;
        } else if (rowIdx >= rows.length - 4) {
          category = SeatCategory.PREMIUM;
        } else {
          category = SeatCategory.STANDARD;
        }
        for (let num = 1; num <= seatsPerRow; num++) {
          seatsToCreate.push({ screenId: screen.id, row, number: num, category });
        }
      }
      await prisma.seat.createMany({ data: seatsToCreate });

      allScreens.push({ id: screen.id, type: screen.type, format: screen.format });
      console.log(`   ✓ ${theatre.name} → ${sSpec.name} (${seatsToCreate.length} seats)`);
    }
  }

  // ── Shows ──────────────────────────────────────────────────────────────────
  console.log('🎞️  Seeding Shows (next 14 days)...');
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  let showsCreated = 0;
  for (let dayOffset = 0; dayOffset < 14; dayOffset++) {
    const showDate = new Date(today);
    showDate.setDate(today.getDate() + dayOffset);

    for (const screen of allScreens) {
      const movie = createdMovies[showsCreated % createdMovies.length]!;
      for (const time of SHOW_TIMES) {
        const startTime = new Date(showDate);
        startTime.setHours(time.hour, time.min, 0, 0);
        const endTime = new Date(startTime);
        endTime.setMinutes(startTime.getMinutes() + movie.runtimeMin + 20);
        await prisma.show.create({
          data: {
            movieId: movie.id,
            screenId: screen.id,
            startTime,
            endTime,
            basePrice: BASE_PRICE[screen.type],
            language: movie.languages[dayOffset % movie.languages.length] ?? 'English',
            format: screen.format,
          },
        });
        showsCreated++;
      }
    }
  }
  console.log(`   ✓ ${showsCreated} shows created`);

  // ── Sample Booking ─────────────────────────────────────────────────────────
  console.log('🎫  Seeding a sample confirmed booking...');
  const sampleShow = await prisma.show.findFirst({
    include: { screen: { include: { seats: true } } },
  });
  if (sampleShow && sampleShow.screen.seats.length >= 2) {
    const [seat1, seat2] = sampleShow.screen.seats.slice(5, 7) as [
      typeof sampleShow.screen.seats[0],
      typeof sampleShow.screen.seats[0],
    ];
    const pricePer = sampleShow.basePrice;
    const totalCost = pricePer * 2;
    const booking = await prisma.booking.create({
      data: {
        userId: customer.id,
        showId: sampleShow.id,
        status: 'CONFIRMED',
        totalCost,
        seats: {
          create: [
            { showId: sampleShow.id, seatId: seat1.id, pricePaid: pricePer },
            { showId: sampleShow.id, seatId: seat2.id, pricePaid: pricePer },
          ],
        },
      },
    });
    await prisma.payment.create({
      data: {
        bookingId: booking.id,
        amount: totalCost,
        status: 'SUCCESS',
        transactionId: `TXN_SEED_${Date.now()}`,
      },
    });
    console.log(`   ✓ Sample booking created (₹${(totalCost / 100).toFixed(0)})`);
  }

  // ── Admin Activity Log ─────────────────────────────────────────────────────
  await prisma.adminActivityLog.create({
    data: {
      actorId: admin.id,
      action: 'SEED_RUN',
      entity: 'Database',
      metadata: {
        movies:   createdMovies.length,
        theatres: THEATRES.length,
        screens:  allScreens.length,
        shows:    showsCreated,
      },
    },
  });

  console.log('\n✅  Seeding finished successfully!');
  console.log(`   Movies    : ${createdMovies.length}`);
  console.log(`   Theatres  : ${THEATRES.length}`);
  console.log(`   Screens   : ${allScreens.length}`);
  console.log(`   Shows     : ${showsCreated}`);
}

main()
  .catch(e => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
