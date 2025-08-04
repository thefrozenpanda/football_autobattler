import React, { useState } from 'react';

const FootballAutobattlerWireframe = () => {
  const [currentScreen, setCurrentScreen] = useState('start');
  const [activeTab, setActiveTab] = useState('training');
  const [offenseType, setOffenseType] = useState('');
  const [defenseType, setDefenseType] = useState('');
  const [difficulty, setDifficulty] = useState('');
  const [offensiveTactic, setOffensiveTactic] = useState('');
  const [defensiveTactic, setDefensiveTactic] = useState('');
  const [trainingPoints, setTrainingPoints] = useState(0);
  const [runNumber, setRunNumber] = useState(1);

  // All data definitions moved to top level
  const offenseTypes = [
    { id: 'pass', name: 'Pass Heavy', desc: 'Focus on aerial attack' },
    { id: 'run', name: 'Run Heavy', desc: 'Pound the ground game' },
    { id: 'balanced', name: 'Balanced', desc: 'Mix of run and pass' }
  ];

  const defenseTypes = [
    { id: 'pass', name: 'Pass Prevent', desc: 'Stop the passing game' },
    { id: 'run', name: 'Run Stopper', desc: 'Shut down the run' },
    { id: 'balanced', name: 'Balanced', desc: 'Versatile defense' }
  ];

  const difficulties = [
    { id: 'underdog', name: 'Underdog', points: 75, desc: 'Low starting training points' },
    { id: 'normal', name: 'Normal', points: 125, desc: 'Average starting training points' },
    { id: 'favorite', name: 'Favorite To Win', points: 200, desc: 'High starting training points' }
  ];

  const offensivePlayers = [
    { id: 1, position: 'QB', name: 'John Smith', stats: { passing: 75, rushing: 45, leadership: 80 } },
    { id: 2, position: 'RB', name: 'Mike Johnson', stats: { rushing: 85, receiving: 60, blocking: 50 } },
    { id: 3, position: 'FB', name: 'Tom Wilson', stats: { rushing: 65, blocking: 90, receiving: 40 } },
    { id: 4, position: 'WR', name: 'Chris Davis', stats: { receiving: 88, speed: 92, route: 85 } },
    { id: 5, position: 'WR', name: 'Alex Brown', stats: { receiving: 82, speed: 87, route: 80 } },
    { id: 6, position: 'WR', name: 'Sam Miller', stats: { receiving: 75, speed: 83, route: 78 } },
    { id: 7, position: 'TE', name: 'Dave Garcia', stats: { receiving: 70, blocking: 85, hands: 80 } },
    { id: 8, position: 'LT', name: 'Rob Taylor', stats: { blocking: 92, strength: 88, technique: 85 } },
    { id: 9, position: 'LG', name: 'Joe Martinez', stats: { blocking: 88, strength: 85, technique: 82 } },
    { id: 10, position: 'C', name: 'Bill Anderson', stats: { blocking: 90, strength: 83, snapping: 95 } },
    { id: 11, position: 'RG', name: 'Pat Thomas', stats: { blocking: 87, strength: 86, technique: 83 } }
  ];

  const defensivePlayers = [
    { id: 12, position: 'DE', name: 'Mark Jackson', stats: { passRush: 88, runStop: 82, strength: 85 } },
    { id: 13, position: 'DT', name: 'Steve White', stats: { passRush: 75, runStop: 92, strength: 90 } },
    { id: 14, position: 'DT', name: 'Dan Harris', stats: { passRush: 78, runStop: 88, strength: 87 } },
    { id: 15, position: 'DE', name: 'Jim Clark', stats: { passRush: 85, runStop: 80, strength: 83 } },
    { id: 16, position: 'LB', name: 'Tony Lewis', stats: { coverage: 75, runStop: 88, tackling: 90 } },
    { id: 17, position: 'LB', name: 'Ryan Walker', stats: { coverage: 70, runStop: 85, tackling: 87 } },
    { id: 18, position: 'LB', name: 'Ken Hall', stats: { coverage: 80, runStop: 82, tackling: 85 } },
    { id: 19, position: 'CB', name: 'Carl Allen', stats: { coverage: 92, speed: 90, tackling: 70 } },
    { id: 20, position: 'CB', name: 'Luke Young', stats: { coverage: 88, speed: 87, tackling: 72 } },
    { id: 21, position: 'S', name: 'Ben King', stats: { coverage: 85, tackling: 88, range: 90 } },
    { id: 22, position: 'S', name: 'Nick Wright', stats: { coverage: 80, tackling: 85, range: 87 } }
  ];

  const availableUpgrades = [
    { id: 1, name: 'Team Speed Training', cost: 15, type: 'team', category: 'offense', desc: '+2 Speed to all offensive players' },
    { id: 2, name: 'Defensive Coordination', cost: 20, type: 'team', category: 'defense', desc: '+3 Tackling to all defensive players' },
    { id: 3, name: 'Conditioning Program', cost: 25, type: 'team', category: 'both', desc: '+5 Stamina to all players' },
    { id: 4, name: 'Elite QB Training', cost: 45, type: 'player', category: 'offense', desc: '+8 Passing accuracy for QB' },
    { id: 5, name: 'Pass Rush Specialist', cost: 40, type: 'player', category: 'defense', desc: '+10 Pass rush for selected DE/DT' },
    { id: 6, name: 'Receiver Route Package', cost: 35, type: 'player', category: 'offense', desc: '+7 Route running for selected WR/TE' }
  ];

  const offensiveTactics = [
    { id: 'aggressive', name: 'Aggressive', desc: 'Take more risks, go for big plays' },
    { id: 'conservative', name: 'Conservative', desc: 'Play it safe, avoid turnovers' },
    { id: 'balanced', name: 'Balanced', desc: 'Mix of safe and aggressive plays' }
  ];

  const defensiveTactics = [
    { id: 'aggressive', name: 'Aggressive', desc: 'Blitz more, take risks for turnovers' },
    { id: 'conservative', name: 'Conservative', desc: 'Prevent big plays, bend but don\'t break' },
    { id: 'balanced', name: 'Balanced', desc: 'Adaptable defensive approach' }
  ];

  const tabs = [
    { id: 'training', name: 'Training Camp' },
    { id: 'scouting', name: 'Scouting' },
    { id: 'schedule', name: 'Schedule' },
    { id: 'standings', name: 'Standings' }
  ];

  const schedule = [
    { week: 1, opponent: 'vs Cowboys', status: 'completed', score: 'W 24-17' },
    { week: 2, opponent: '@ Giants', status: 'upcoming' },
    { week: 3, opponent: 'vs Eagles', status: 'upcoming' },
    { week: 4, opponent: '@ Commanders', status: 'upcoming' },
    { week: 5, opponent: 'vs 49ers', status: 'upcoming' },
    { week: 6, opponent: '@ Seahawks', status: 'upcoming' },
    { week: 7, opponent: 'vs Cardinals', status: 'upcoming' },
    { week: 8, opponent: '@ Rams', status: 'upcoming' },
    { week: 9, opponent: 'BYE WEEK', status: 'bye' },
    { week: 10, opponent: 'vs Packers', status: 'upcoming' },
    { week: 11, opponent: '@ Bears', status: 'upcoming' },
    { week: 12, opponent: 'vs Lions', status: 'upcoming' },
    { week: 13, opponent: '@ Vikings', status: 'upcoming' },
    { week: 14, opponent: 'vs Chiefs', status: 'upcoming' },
    { week: 15, opponent: '@ Broncos', status: 'upcoming' },
    { week: 16, opponent: 'vs Raiders', status: 'upcoming' },
    { week: 17, opponent: '@ Chargers', status: 'upcoming' }
  ];

  const divisions = {
    'AFC East': [
      { team: 'Bills', record: '1-0', pf: 31, pa: 17 },
      { team: 'Dolphins', record: '1-0', pf: 28, pa: 14 },
      { team: 'Patriots', record: '0-1', pf: 14, pa: 28 },
      { team: 'Jets', record: '0-1', pf: 17, pa: 31 }
    ],
    'AFC North': [
      { team: 'Ravens', record: '1-0', pf: 27, pa: 20 },
      { team: 'Bengals', record: '1-0', pf: 24, pa: 21 },
      { team: 'Steelers', record: '0-1', pf: 21, pa: 24 },
      { team: 'Browns', record: '0-1', pf: 20, pa: 27 }
    ],
    'AFC South': [
      { team: 'Texans', record: '1-0', pf: 29, pa: 16 },
      { team: 'Colts', record: '1-0', pf: 22, pa: 19 },
      { team: 'Titans', record: '0-1', pf: 19, pa: 22 },
      { team: 'Jaguars', record: '0-1', pf: 16, pa: 29 }
    ],
    'AFC West': [
      { team: 'Chiefs', record: '1-0', pf: 26, pa: 13 },
      { team: 'Chargers', record: '1-0', pf: 25, pa: 18 },
      { team: 'Raiders', record: '0-1', pf: 18, pa: 25 },
      { team: 'Broncos', record: '0-1', pf: 13, pa: 26 }
    ],
    'NFC East': [
      { team: 'Your Team', record: '1-0', pf: 24, pa: 17 },
      { team: 'Eagles', record: '1-0', pf: 30, pa: 14 },
      { team: 'Giants', record: '0-1', pf: 14, pa: 30 },
      { team: 'Cowboys', record: '0-1', pf: 17, pa: 24 }
    ],
    'NFC North': [
      { team: 'Lions', record: '1-0', pf: 32, pa: 21 },
      { team: 'Packers', record: '1-0', pf: 23, pa: 20 },
      { team: 'Vikings', record: '0-1', pf: 20, pa: 23 },
      { team: 'Bears', record: '0-1', pf: 21, pa: 32 }
    ],
    'NFC South': [
      { team: 'Saints', record: '1-0', pf: 28, pa: 17 },
      { team: 'Falcons', record: '1-0', pf: 24, pa: 20 },
      { team: 'Panthers', record: '0-1', pf: 20, pa: 24 },
      { team: 'Buccaneers', record: '0-1', pf: 17, pa: 28 }
    ],
    'NFC West': [
      { team: '49ers', record: '1-0', pf: 35, pa: 24 },
      { team: 'Seahawks', record: '1-0', pf: 27, pa: 23 },
      { team: 'Cardinals', record: '0-1', pf: 23, pa: 27 },
      { team: 'Rams', record: '0-1', pf: 24, pa: 35 }
    ]
  };

  const Screen = ({ children, title }) => (
    <div className="min-h-screen bg-green-50 p-4">
      <div className="max-w-7xl mx-auto">
        <div className="bg-white border-2 border-green-600 rounded-lg p-6 shadow-lg">
          <div className="border-b-2 border-green-200 pb-4 mb-6">
            <h1 className="text-2xl font-bold text-green-800">{title}</h1>
            <div className="flex justify-between mt-2 text-sm text-gray-600">
              <span>Season #{runNumber}</span>
              <span>Training Points: {trainingPoints}</span>
            </div>
          </div>
          {children}
        </div>
      </div>
    </div>
  );

  const PlayerCard = ({ player, type }) => (
    <div className="border border-gray-300 p-3 rounded bg-white shadow-sm">
      <div className="font-semibold text-sm">{player.position}</div>
      <div className="text-xs text-gray-700 mb-2">{player.name}</div>
      <div className="text-xs space-y-1">
        {Object.entries(player.stats).map(([stat, value]) => (
          <div key={stat} className="flex justify-between">
            <span className="capitalize">{stat}:</span>
            <span className="font-semibold">{value}</span>
          </div>
        ))}
      </div>
    </div>
  );

  if (currentScreen === 'start') {
    const canBegin = offenseType && defenseType && difficulty;
    
    return (
      <Screen title="Start New Season">
        <div className="space-y-8">
          {/* Offensive Type Selection */}
          <div>
            <h2 className="text-xl font-bold mb-4 text-blue-600">Select Offensive Style</h2>
            <div className="grid grid-cols-3 gap-4">
              {offenseTypes.map(type => (
                <div 
                  key={type.id}
                  className={`border-2 p-4 rounded-lg cursor-pointer transition-all ${
                    offenseType === type.id 
                      ? 'border-blue-500 bg-blue-50' 
                      : 'border-gray-300 hover:border-gray-400'
                  }`}
                  onClick={() => setOffenseType(type.id)}
                >
                  <div className="flex items-center space-x-3">
                    <div className={`w-4 h-4 rounded-full border-2 ${
                      offenseType === type.id ? 'bg-blue-500 border-blue-500' : 'border-gray-300'
                    }`}></div>
                    <div>
                      <div className="font-semibold">{type.name}</div>
                      <div className="text-sm text-gray-600">{type.desc}</div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Defensive Type Selection */}
          <div>
            <h2 className="text-xl font-bold mb-4 text-red-600">Select Defensive Style</h2>
            <div className="grid grid-cols-3 gap-4">
              {defenseTypes.map(type => (
                <div 
                  key={type.id}
                  className={`border-2 p-4 rounded-lg cursor-pointer transition-all ${
                    defenseType === type.id 
                      ? 'border-red-500 bg-red-50' 
                      : 'border-gray-300 hover:border-gray-400'
                  }`}
                  onClick={() => setDefenseType(type.id)}
                >
                  <div className="flex items-center space-x-3">
                    <div className={`w-4 h-4 rounded-full border-2 ${
                      defenseType === type.id ? 'bg-red-500 border-red-500' : 'border-gray-300'
                    }`}></div>
                    <div>
                      <div className="font-semibold">{type.name}</div>
                      <div className="text-sm text-gray-600">{type.desc}</div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Difficulty Selection */}
          <div>
            <h2 className="text-xl font-bold mb-4 text-green-600">Select Difficulty</h2>
            <div className="grid grid-cols-3 gap-4">
              {difficulties.map(diff => (
                <div 
                  key={diff.id}
                  className={`border-2 p-4 rounded-lg cursor-pointer transition-all ${
                    difficulty === diff.id 
                      ? 'border-green-500 bg-green-50' 
                      : 'border-gray-300 hover:border-gray-400'
                  }`}
                  onClick={() => {
                    setDifficulty(diff.id);
                    setTrainingPoints(diff.points);
                  }}
                >
                  <div className="flex items-center space-x-3">
                    <div className={`w-4 h-4 rounded-full border-2 ${
                      difficulty === diff.id ? 'bg-green-500 border-green-500' : 'border-gray-300'
                    }`}></div>
                    <div>
                      <div className="font-semibold">{diff.name}</div>
                      <div className="text-sm text-gray-600">{diff.desc}</div>
                      <div className="text-sm font-bold text-green-600">{diff.points} Training Points</div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="text-center pt-6">
            <button 
              onClick={() => setCurrentScreen('shop')}
              disabled={!canBegin}
              className={`px-8 py-3 rounded-lg text-lg font-semibold ${
                canBegin 
                  ? 'bg-green-600 text-white hover:bg-green-700' 
                  : 'bg-gray-300 text-gray-500 cursor-not-allowed'
              }`}
            >
              Begin Season
            </button>
            {!canBegin && (
              <div className="text-sm text-gray-500 mt-2">
                Please select offensive style, defensive style, and difficulty
              </div>
            )}
          </div>
        </div>
      </Screen>
    );
  }

  if (currentScreen === 'shop') {
    return (
      <Screen title="Team Management">
        {/* Tab Navigation */}
        <div className="border-b border-gray-200 mb-6">
          <nav className="flex space-x-8">
            {tabs.map(tab => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`py-2 px-1 border-b-2 font-medium text-sm ${
                  activeTab === tab.id
                    ? 'border-green-500 text-green-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                {tab.name}
              </button>
            ))}
          </nav>
        </div>

        {/* Training Camp Tab */}
        {activeTab === 'training' && (
          <div className="grid grid-cols-3 gap-6">
            {/* Available Upgrades - Left Side */}
            <div>
              <h2 className="text-xl mb-4 border-b border-gray-200 pb-2">Available Training</h2>
              <div className="space-y-3">
                {availableUpgrades.slice(0, 4).map(upgrade => (
                  <div key={upgrade.id} className="border border-gray-300 p-4 rounded">
                    <div className="flex justify-between items-start mb-2">
                      <div className="flex-1">
                        <div className="font-semibold">{upgrade.name}</div>
                        <div className={`inline-block px-2 py-1 rounded text-xs font-semibold ${
                          upgrade.category === 'offense' ? 'bg-blue-100 text-blue-800' :
                          upgrade.category === 'defense' ? 'bg-red-100 text-red-800' :
                          'bg-green-100 text-green-800'
                        }`}>
                          {upgrade.category === 'both' ? 'Team' : upgrade.category}
                        </div>
                        <div className={`inline-block px-2 py-1 rounded text-xs ml-1 ${
                          upgrade.type === 'team' ? 'bg-purple-100 text-purple-800' : 'bg-orange-100 text-orange-800'
                        }`}>
                          {upgrade.type}
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="font-bold">{upgrade.cost} TP</div>
                      </div>
                    </div>
                    <div className="text-sm text-gray-600 mb-2">{upgrade.desc}</div>
                    <button className="text-sm bg-green-600 text-white px-3 py-1 rounded hover:bg-green-700">
                      Purchase
                    </button>
                  </div>
                ))}
              </div>
              <button className="mt-4 text-green-600 border border-green-600 px-4 py-2 rounded hover:bg-green-50">
                Refresh Available Training (15 TP)
              </button>
            </div>
            
            {/* Offensive Players - Top Right */}
            <div className="col-span-2">
              <div className="mb-6">
                <h2 className="text-xl mb-4 border-b border-blue-200 pb-2 text-blue-600">Offensive Squad (11 Players)</h2>
                <div className="grid grid-cols-4 gap-3">
                  {offensivePlayers.map(player => (
                    <PlayerCard key={player.id} player={player} type="offense" />
                  ))}
                </div>
              </div>

              {/* Defensive Players - Bottom Right */}
              <div>
                <h2 className="text-xl mb-4 border-b border-red-200 pb-2 text-red-600">Defensive Squad (11 Players)</h2>
                <div className="grid grid-cols-4 gap-3">
                  {defensivePlayers.map(player => (
                    <PlayerCard key={player.id} player={player} type="defense" />
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Scouting Tab */}
        {activeTab === 'scouting' && (
          <div className="max-w-4xl mx-auto">
            <div className="text-center mb-6">
              <h2 className="text-xl font-bold text-gray-800">Next Opponent: New York Giants</h2>
              <p className="text-gray-600">Week 2 - Away Game</p>
            </div>

            <div className="grid grid-cols-3 gap-6">
              <div className="border border-gray-300 rounded-lg p-6 hover:shadow-md transition-shadow">
                <h3 className="font-bold mb-4 text-center">Team Tendencies</h3>
                <div className="text-center mb-4">
                  <div className="text-2xl font-bold text-green-600">10 TP</div>
                </div>
                <div className="text-sm text-gray-600 mb-4">
                  Reveals opponent's general offensive and defensive tendencies, strengths, and weaknesses.
                </div>
                <button className="w-full bg-green-600 text-white py-2 rounded hover:bg-green-700">
                  Scout Tendencies
                </button>
              </div>

              <div className="border border-gray-300 rounded-lg p-6 hover:shadow-md transition-shadow">
                <h3 className="font-bold mb-4 text-center text-blue-600">Offensive Roster</h3>
                <div className="text-center mb-4">
                  <div className="text-2xl font-bold text-green-600">25 TP</div>
                </div>
                <div className="text-sm text-gray-600 mb-4">
                  Full breakdown of all 11 offensive players with detailed stats and capabilities.
                </div>
                <button className="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700">
                  Scout Offense
                </button>
              </div>

              <div className="border border-gray-300 rounded-lg p-6 hover:shadow-md transition-shadow">
                <h3 className="font-bold mb-4 text-center text-red-600">Defensive Roster</h3>
                <div className="text-center mb-4">
                  <div className="text-2xl font-bold text-green-600">25 TP</div>
                </div>
                <div className="text-sm text-gray-600 mb-4">
                  Full breakdown of all 11 defensive players with detailed stats and capabilities.
                </div>
                <button className="w-full bg-red-600 text-white py-2 rounded hover:bg-red-700">
                  Scout Defense
                </button>
              </div>
            </div>

            <div className="mt-8 border-t pt-6">
              <h3 className="font-bold mb-4">Previous Scouting Reports</h3>
              <div className="bg-gray-50 p-4 rounded-lg">
                <div className="text-sm text-gray-600">
                  <strong>Cowboys (Week 1):</strong> Strong running game, weak pass defense. Aggressive defensive style.
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Schedule Tab */}
        {activeTab === 'schedule' && (
          <div className="max-w-4xl mx-auto">
            <h2 className="text-xl font-bold mb-6 text-center">2024 Season Schedule</h2>
            <div className="grid grid-cols-2 gap-6">
              {schedule.map(game => (
                <div key={game.week} className={`border rounded-lg p-4 ${
                  game.status === 'completed' ? 'bg-green-50 border-green-200' :
                  game.status === 'bye' ? 'bg-gray-50 border-gray-200' :
                  'bg-white border-gray-300'
                }`}>
                  <div className="flex justify-between items-start">
                    <div>
                      <div className="font-bold">Week {game.week}</div>
                      <div className="text-sm text-gray-600">{game.opponent}</div>
                      {game.status === 'completed' && (
                        <div className="text-sm font-semibold text-green-600 mt-1">
                          {game.score}
                        </div>
                      )}
                    </div>
                    {game.status === 'completed' && (
                      <button className="text-xs bg-blue-600 text-white px-2 py-1 rounded">
                        View Analysis
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Standings Tab */}
        {activeTab === 'standings' && (
          <div className="max-w-6xl mx-auto">
            <h2 className="text-xl font-bold mb-6 text-center">NFL Standings - Week 1</h2>
            <div className="grid grid-cols-2 gap-6">
              {Object.entries(divisions).map(([divisionName, teams]) => (
                <div key={divisionName} className="border border-gray-300 rounded-lg overflow-hidden">
                  <div className="bg-gray-100 px-4 py-2 font-bold text-center">
                    {divisionName}
                  </div>
                  <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                      <thead className="bg-gray-50">
                        <tr>
                          <th className="px-3 py-2 text-left">Team</th>
                          <th className="px-3 py-2 text-center">W-L</th>
                          <th className="px-3 py-2 text-center">PF</th>
                          <th className="px-3 py-2 text-center">PA</th>
                        </tr>
                      </thead>
                      <tbody>
                        {teams.map(team => (
                          <tr key={team.team} className={`border-t ${
                            team.team === 'Your Team' ? 'bg-green-50 font-semibold' : ''
                          }`}>
                            <td className="px-3 py-2">{team.team}</td>
                            <td className="px-3 py-2 text-center">{team.record}</td>
                            <td className="px-3 py-2 text-center">{team.pf}</td>
                            <td className="px-3 py-2 text-center">{team.pa}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
        
        <div className="mt-6 flex justify-between">
          <button 
            onClick={() => setCurrentScreen('start')}
            className="bg-gray-500 text-white px-6 py-2 rounded hover:bg-gray-600"
          >
            Back
          </button>
          <button 
            onClick={() => setCurrentScreen('tactics')}
            className="bg-green-600 text-white px-6 py-2 rounded hover:bg-green-700"
          >
            Continue to Game Plan
          </button>
        </div>
      </Screen>
    );
  }

  if (currentScreen === 'tactics') {
    const canStart = offensiveTactic && defensiveTactic;

    return (
      <Screen title="Select Game Tactics">
        <div className="max-w-4xl mx-auto space-y-8">
          {/* Offensive Tactics */}
          <div>
            <h2 className="text-xl mb-6 text-center text-blue-600 font-bold">Offensive Game Plan</h2>
            <div className="grid grid-cols-3 gap-4">
              {offensiveTactics.map(tactic => (
                <div 
                  key={tactic.id}
                  className={`border-2 p-4 rounded-lg cursor-pointer transition-all ${
                    offensiveTactic === tactic.id 
                      ? 'border-blue-500 bg-blue-50' 
                      : 'border-gray-300 hover:border-gray-400'
                  }`}
                  onClick={() => setOffensiveTactic(tactic.id)}
                >
                  <div className="flex items-center space-x-3">
                    <div className={`w-4 h-4 rounded-full border-2 ${
                      offensiveTactic === tactic.id ? 'bg-blue-500 border-blue-500' : 'border-gray-300'
                    }`}></div>
                    <div>
                      <div className="font-semibold">{tactic.name}</div>
                      <div className="text-sm text-gray-600">{tactic.desc}</div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Defensive Tactics */}
          <div>
            <h2 className="text-xl mb-6 text-center text-red-600 font-bold">Defensive Game Plan</h2>
            <div className="grid grid-cols-3 gap-4">
              {defensiveTactics.map(tactic => (
                <div 
                  key={tactic.id}
                  className={`border-2 p-4 rounded-lg cursor-pointer transition-all ${
                    defensiveTactic === tactic.id 
                      ? 'border-red-500 bg-red-50' 
                      : 'border-gray-300 hover:border-gray-400'
                  }`}
                  onClick={() => setDefensiveTactic(tactic.id)}
                >
                  <div className="flex items-center space-x-3">
                    <div className={`w-4 h-4 rounded-full border-2 ${
                      defensiveTactic === tactic.id ? 'bg-red-500 border-red-500' : 'border-gray-300'
                    }`}></div>
                    <div>
                      <div className="font-semibold">{tactic.name}</div>
                      <div className="text-sm text-gray-600">{tactic.desc}</div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Formation Preview */}
          <div className="border-t pt-6">
            <h3 className="font-semibold mb-4 text-center">Formation Preview</h3>
            <div className="border-2 border-dashed border-gray-300 p-6 rounded-lg bg-green-50">
              <div className="grid grid-cols-2 gap-8">
                <div>
                  <h4 className="font-semibold text-blue-600 mb-2 text-center">Offensive Formation</h4>
                  <div className="grid grid-cols-3 gap-2 text-center">
                    <div className="col-span-3 border border-blue-400 p-2 rounded bg-blue-50 text-xs">
                      WR - QB - WR
                    </div>
                    <div className="border border-blue-400 p-2 rounded bg-blue-50 text-xs">OL</div>
                    <div className="border border-blue-400 p-2 rounded bg-blue-50 text-xs">RB</div>
                    <div className="border border-blue-400 p-2 rounded bg-blue-50 text-xs">TE</div>
                  </div>
                </div>
                <div>
                  <h4 className="font-semibold text-red-600 mb-2 text-center">Defensive Formation</h4>
                  <div className="grid grid-cols-3 gap-2 text-center">
                    <div className="border border-red-400 p-2 rounded bg-red-50 text-xs">DE</div>
                    <div className="border border-red-400 p-2 rounded bg-red-50 text-xs">DT</div>
                    <div className="border border-red-400 p-2 rounded bg-red-50 text-xs">DE</div>
                    <div className="col-span-3 border border-red-400 p-2 rounded bg-red-50 text-xs">
                      LB - CB - S
                    </div>
                  </div>
                </div>
              </div>
              <div className="text-sm text-gray-500 text-center mt-3">
                Formation adjusts based on selected tactics
              </div>
            </div>
          </div>

          <div className="flex justify-between pt-6">
            <button 
              onClick={() => setCurrentScreen('shop')}
              className="bg-gray-500 text-white px-6 py-2 rounded hover:bg-gray-600"
            >
              Back to Training
            </button>
            <button 
              onClick={() => setCurrentScreen('battle')}
              disabled={!canStart}
              className={`px-8 py-2 rounded text-lg font-semibold ${
                canStart 
                  ? 'bg-green-600 text-white hover:bg-green-700' 
                  : 'bg-gray-300 text-gray-500 cursor-not-allowed'
              }`}
            >
              Start Game!
            </button>
            {!canStart && (
              <div className="text-sm text-gray-500 mt-2">
                Select both offensive and defensive tactics
              </div>
            )}
          </div>
        </div>
      </Screen>
    );
  }

  if (currentScreen === 'battle') {
    return (
      <Screen title="Game in Progress">
        <div className="text-center">
          <div className="mb-6">
            <h2 className="text-xl mb-2">Week 1 - 2nd Quarter</h2>
            <div className="text-sm text-gray-600">
              Offense: {offensiveTactics.find(t => t.id === offensiveTactic)?.name} | 
              Defense: {defensiveTactics.find(t => t.id === defensiveTactic)?.name}
            </div>
          </div>

          <div className="border-2 border-green-600 rounded-lg p-6 bg-green-50 mb-6">
            <div className="grid grid-cols-2 gap-12">
              <div>
                <h3 className="font-semibold mb-4 text-blue-600">Your Team: 14</h3>
                <div className="text-lg font-bold">3rd & 7 at OPP 35</div>
                <div className="text-sm text-gray-600 mt-2">Driving for touchdown</div>
              </div>

              <div>
                <h3 className="font-semibold mb-4 text-red-600">Opponent: 10</h3>
                <div className="text-lg font-bold">Defending</div>
                <div className="text-sm text-gray-600 mt-2">Trying to force punt</div>
              </div>
            </div>

            <div className="mt-6 text-center">
              <div className="text-sm text-gray-600 mb-2">Game Simulation Area</div>
              <div className="text-lg font-semibold text-green-600">Your offense is moving the ball well!</div>
            </div>
          </div>

          <div className="space-x-4">
            <button className="bg-gray-500 text-white px-4 py-2 rounded">
              Pause
            </button>
            <button className="bg-blue-500 text-white px-4 py-2 rounded">
              Speed Up (2x)
            </button>
            <button 
              onClick={() => setCurrentScreen('victory')}
              className="bg-green-500 text-white px-4 py-2 rounded"
            >
              Skip to Final Score
            </button>
          </div>
        </div>
      </Screen>
    );
  }

  if (currentScreen === 'victory') {
    return (
      <Screen title="Game Complete!">
        <div className="text-center max-w-2xl mx-auto">
          <div className="mb-6">
            <h2 className="text-2xl text-green-600 font-bold mb-2">Victory! 24-17</h2>
            <div className="text-gray-600">Your game plan was effective</div>
          </div>

          <div className="border-2 border-green-500 rounded-lg p-6 bg-green-50 mb-6">
            <h3 className="font-semibold mb-4">Game Results</h3>
            <div className="grid grid-cols-2 gap-6 text-left">
              <div>
                <h4 className="font-semibold mb-2">Rewards Earned:</h4>
                <ul className="text-sm space-y-1">
                  <li>+ 75 Training Points</li>
                  <li>+ Experience for all players</li>
                  <li>+ 1 Elite training session</li>
                </ul>
              </div>
              <div>
                <h4 className="font-semibold mb-2">Key Stats:</h4>
                <ul className="text-sm space-y-1">
                  <li>Total yards: 387</li>
                  <li>Turnovers: 1</li>
                  <li>3rd down: 7/12</li>
                </ul>
              </div>
            </div>
          </div>

          <div className="space-x-4">
            <button 
              onClick={() => {
                setCurrentScreen('shop');
                setTrainingPoints(trainingPoints + 75);
              }}
              className="bg-green-600 text-white px-8 py-3 rounded-lg text-lg hover:bg-green-700"
            >
              Continue Season
            </button>
            <button className="bg-gray-500 text-white px-6 py-2 rounded hover:bg-gray-600">
              End Season
            </button>
          </div>
        </div>
      </Screen>
    );
  }

  return null;
};

export default FootballAutobattlerWireframe;