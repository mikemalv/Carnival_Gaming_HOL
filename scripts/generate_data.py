import csv, random, os
from datetime import datetime, timedelta

random.seed(42)
DATA_DIR = '/Users/mmalveira/Desktop/Snowwork/Carnival_HOL/data'

ships = [
    (1,'Mardi Gras','Carnival',5282,'Port Canaveral',2020),
    (2,'Celebration','Carnival',5374,'Miami',2022),
    (3,'Jubilee','Carnival',5374,'Galveston',2023),
    (4,'Carnival Venezia','Carnival',4072,'New York',2023),
    (5,'Carnival Firenze','Carnival',4072,'Long Beach',2024),
    (6,'Carnival Panorama','Carnival',4008,'Long Beach',2019),
    (7,'Rotterdam','Holland America',2668,'Fort Lauderdale',2021),
    (8,'Nieuw Statendam','Holland America',2666,'Fort Lauderdale',2018),
    (9,'Koningsdam','Holland America',2650,'San Diego',2016),
    (10,'Zuiderdam','Holland America',1964,'Fort Lauderdale',2002),
    (11,'Westerdam','Holland America',1964,'Seattle',2004),
    (12,'Volendam','Holland America',1432,'Fort Lauderdale',2000),
]
with open(f'{DATA_DIR}/ships.csv','w',newline='') as f:
    w=csv.writer(f)
    w.writerow(['ship_id','ship_name','brand','passenger_capacity','home_port','launch_year'])
    w.writerows(ships)

itineraries = [
    ('Eastern Caribbean 7-Day',3,4),('Western Caribbean 7-Day',3,4),
    ('Southern Caribbean 10-Day',4,6),('Bahamas 4-Day',1,3),
    ('Mexican Riviera 7-Day',3,4),('Alaska 7-Day',3,4),
    ('Mediterranean 14-Day',5,9),('Panama Canal 11-Day',4,7),
    ('Bermuda 5-Day',2,3),('Hawaii 15-Day',6,9),
]
voyages = []
vid = 1
base = datetime(2025,10,1)
for ship_id in range(1,13):
    d = base
    for _ in range(5):
        itin_name,sea,port = random.choice(itineraries)
        dur = sea + port
        voyages.append((vid,ship_id,d.strftime('%Y-%m-%d'),(d+timedelta(days=dur)).strftime('%Y-%m-%d'),itin_name,sea,port))
        d += timedelta(days=dur+1)
        vid += 1
with open(f'{DATA_DIR}/voyages.csv','w',newline='') as f:
    w=csv.writer(f)
    w.writerow(['voyage_id','ship_id','departure_date','return_date','itinerary_name','sea_days','port_days'])
    w.writerows(voyages)

games = []
gid = 1
slot_names = ['Lucky 7s Deluxe','Caribbean Gold','Pirates Fortune','Ocean Jackpot','Coral Reef Riches',
              'Treasure Island Slots','Neptunes Bounty','Cruise Cash','Sunset Spin','Diamond Waves']
for n in slot_names:
    games.append((gid,'Slots',n,0.25,100.00,'Deck '+str(random.choice([6,7,8]))))
    gid+=1
table_games = [
    ('Blackjack','Classic Blackjack',10,500),('Blackjack','VIP Blackjack',25,2000),
    ('Blackjack','Blackjack Switch',15,1000),
    ('Poker','Texas Holdem',20,500),('Poker','Caribbean Stud Poker',10,300),
    ('Poker','Three Card Poker',10,500),
    ('Roulette','American Roulette',5,500),('Roulette','European Roulette',5,500),
    ('Craps','Classic Craps',5,500),('Craps','High-Roller Craps',25,2000),
    ('Baccarat','Mini Baccarat',15,1000),('Baccarat','VIP Baccarat',50,5000),
]
for gt,gn,mn,mx in table_games:
    games.append((gid,gt,gn,mn,mx,'Deck '+str(random.choice([7,8,9]))))
    gid+=1
with open(f'{DATA_DIR}/casino_games.csv','w',newline='') as f:
    w=csv.writer(f)
    w.writerow(['game_id','game_type','game_name','min_bet','max_bet','location_deck'])
    w.writerows(games)

first_names = ['James','Mary','John','Patricia','Robert','Jennifer','Michael','Linda','David','Elizabeth',
    'William','Barbara','Richard','Susan','Joseph','Jessica','Thomas','Sarah','Christopher','Karen',
    'Carlos','Maria','Luis','Ana','Pedro','Rosa','Hiroshi','Yuki','Wei','Min',
    'Ahmed','Fatima','Raj','Priya','Chen','Ling','Marco','Sofia','Andrei','Olga']
last_names = ['Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Rodriguez','Martinez',
    'Hernandez','Lopez','Gonzalez','Wilson','Anderson','Thomas','Taylor','Moore','Jackson','Martin',
    'Lee','Perez','Thompson','White','Harris','Sanchez','Clark','Ramirez','Lewis','Robinson']
cities = ['Miami FL','New York NY','Los Angeles CA','Houston TX','Chicago IL','Phoenix AZ',
    'San Diego CA','Dallas TX','Denver CO','Seattle WA','Atlanta GA','Boston MA',
    'Nashville TN','Tampa FL','Orlando FL','Fort Lauderdale FL','Las Vegas NV','San Francisco CA']
tiers = ['Bronze','Silver','Gold','Platinum','Diamond']
tier_w = [40,25,20,10,5]

players = []
for pid in range(1,501):
    fn=random.choice(first_names)
    ln=random.choice(last_names)
    cs=random.choice(cities)
    city,state=cs.rsplit(' ',1)
    email=f'{fn.lower()}.{ln.lower()}{pid}@email.com'
    phone=f'+1-{random.randint(200,999)}-{random.randint(100,999)}-{random.randint(1000,9999)}'
    tier=random.choices(tiers,weights=tier_w,k=1)[0]
    jd=(datetime(2020,1,1)+timedelta(days=random.randint(0,2000))).strftime('%Y-%m-%d')
    players.append((pid,fn,ln,email,phone,tier,city,state,jd))
with open(f'{DATA_DIR}/players.csv','w',newline='') as f:
    w=csv.writer(f)
    w.writerow(['player_id','first_name','last_name','email','phone','loyalty_tier','home_city','home_state','membership_date'])
    w.writerows(players)

txns = []
for txn_id in range(1,50001):
    pid=random.randint(1,500)
    gid_r=random.randint(1,len(games))
    v=random.choice(voyages)
    voyage_id=v[0]
    ship_id=v[1]
    dep=datetime.strptime(v[2],'%Y-%m-%d')
    ret=datetime.strptime(v[3],'%Y-%m-%d')
    ts=dep+timedelta(seconds=random.randint(0,int((ret-dep).total_seconds())))
    game=games[gid_r-1]
    min_b=float(game[3])
    max_b=float(game[4])
    bet=round(random.uniform(min_b,min(max_b,min_b*10)),2)
    gt=game[1]
    if gt=='Slots': edge=random.gauss(0.08,0.15)
    elif gt=='Blackjack': edge=random.gauss(0.02,0.12)
    elif gt=='Roulette': edge=random.gauss(0.053,0.20)
    elif gt=='Baccarat': edge=random.gauss(0.012,0.10)
    else: edge=random.gauss(0.04,0.15)
    payout=round(max(0,bet*(1-edge)),2)
    net_rev=round(bet-payout,2)
    txns.append((txn_id,pid,gid_r,ship_id,voyage_id,ts.strftime('%Y-%m-%d %H:%M:%S'),bet,payout,net_rev))
with open(f'{DATA_DIR}/gaming_transactions.csv','w',newline='') as f:
    w=csv.writer(f)
    w.writerow(['txn_id','player_id','game_id','ship_id','voyage_id','txn_timestamp','bet_amount','payout_amount','net_revenue'])
    w.writerows(txns)

positive_details = [
    'The dealers were friendly and professional, made the experience really enjoyable.',
    'Won big on the slot machines! The atmosphere was electric with everyone cheering.',
    'Great selection of table games. The blackjack tables had reasonable minimums.',
    'The loyalty program rewards were outstanding. Got complimentary drinks all cruise.',
    'Loved the poker tournament on sea days. Well organized with good prize pools.',
    'Casino was beautifully decorated and spacious. Never felt crowded even on peak nights.',
    'The VIP room was a fantastic experience. Personalized service and higher limits.',
    'Staff remembered my name by the second day. That personal touch made all the difference.',
    'Progressive jackpot slots were exciting. Someone won $15,000 on our sailing!',
    'Best casino experience I have had on any cruise line. Will definitely come back.',
]
negative_details = [
    'The minimum bets were too high for casual players. $25 minimum blackjack is excessive.',
    'Casino was extremely smoky. Needs better ventilation or a non-smoking section.',
    'Slot machines seemed very tight. Played for hours without any significant wins.',
    'Dealers were rude and impatient with beginners. Not a welcoming environment.',
    'The casino was too small for the number of passengers. Always crowded and noisy.',
    'Drink service in the casino was painfully slow. Had to wait 30 minutes for a cocktail.',
    'The poker room closed too early. Would have liked late-night tournament options.',
    'Felt like the house edge was much higher than Las Vegas. Not great value.',
    'ATM fees in the casino were outrageous. $8 per transaction is highway robbery.',
    'The loyalty tier system is confusing. Could not figure out how to earn or redeem points.',
]
neutral_details = [
    'Decent casino but nothing extraordinary. Standard cruise ship gaming experience.',
    'Played a few rounds of blackjack. Won some, lost some. Pretty average experience.',
    'The casino was okay. Not as large as I expected but had all the major games.',
    'Spent a couple of evenings playing slots. Normal odds, nothing special to report.',
    'Good for entertainment purposes but do not expect Vegas-level gaming.',
]
review_templates = [
    'The casino on the {ship} was {adj}! {detail}',
    'Had a {adj} time at the {game} tables on the {ship}. {detail}',
    'I {verb} the slot machines on the {ship}. {detail}',
    'Casino experience on our {itin} cruise aboard the {ship}: {detail}',
    'The dealers on the {ship} were {dealer_adj}. {detail}',
    '{detail} Overall, the {ship} casino gets a {rating_word} from me.',
    'Spent most evenings in the casino on the {ship}. {detail}',
    'First time playing {game} on a cruise ship ({ship}). {detail}',
]
adjs=['amazing','fantastic','wonderful','disappointing','terrible','decent','okay','great','outstanding','mediocre']
dealer_adjs=['excellent','professional','friendly','rude','slow','impatient','wonderful','attentive']
verbs=['loved','enjoyed','hated','appreciated','was disappointed by','was thrilled by']
rating_words=['thumbs up','solid recommendation','pass','mixed review','two thumbs up','strong avoid']
game_short=['blackjack','poker','roulette','craps','baccarat','slots']

reviews_out = []
languages = ['en']*85+['es']*8+['de']*4+['fr']*3
for rid in range(1,1001):
    pid=random.randint(1,500)
    v=random.choice(voyages)
    ship_id=v[1]
    ship_name=ships[ship_id-1][1]
    voyage_id=v[0]
    rating=random.choices([1,2,3,4,5],weights=[8,12,20,35,25],k=1)[0]
    if rating>=4: detail=random.choice(positive_details)
    elif rating<=2: detail=random.choice(negative_details)
    else: detail=random.choice(neutral_details)
    tmpl=random.choice(review_templates)
    review=tmpl.format(ship=ship_name,adj=random.choice(adjs),detail=detail,
        game=random.choice(game_short),itin=v[4],
        dealer_adj=random.choice(dealer_adjs),verb=random.choice(verbs),
        rating_word=random.choice(rating_words))
    ret=datetime.strptime(v[3],'%Y-%m-%d')
    rev_date=ret+timedelta(days=random.randint(1,14))
    lang=random.choice(languages)
    reviews_out.append((rid,pid,ship_id,voyage_id,review,rating,rev_date.strftime('%Y-%m-%d'),lang))
with open(f'{DATA_DIR}/player_reviews.csv','w',newline='') as f:
    w=csv.writer(f)
    w.writerow(['review_id','player_id','ship_id','voyage_id','review_text','rating','review_date','language'])
    w.writerows(reviews_out)

for fname in ['ships','voyages','casino_games','players','gaming_transactions','player_reviews']:
    with open(f'{DATA_DIR}/{fname}.csv') as ff:
        lines=sum(1 for _ in ff)-1
    print(f'{fname}.csv: {lines} rows')
print('Done!')
