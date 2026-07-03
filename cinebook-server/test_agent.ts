import { createEmitterState, emitToolCallResult } from './src/agent/aguiEmitter.js';
const state = createEmitterState('test');
const res = { write: (data: string) => console.log('WROTE:', data) };
emitToolCallResult(res as any, state, 'call123', 'requestPreferencesForm', {
  renderHint: 'a2ui',
  surfaceId: 'booking-preferences-form',
  components: [ { type: 'form', children: [] } ]
});
