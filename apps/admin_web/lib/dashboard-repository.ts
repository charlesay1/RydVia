export type BookingStatus = 'completed' | 'active' | 'scheduled';
export type Booking = {id: string; customer: string; service: string; route: string; fare: number; status: BookingStatus; day: number};
export type DashboardFilters = {days: number; service: string};
export interface DashboardRepository { bookings(filters: DashboardFilters): Promise<readonly Booking[]>; }
const fixtures: readonly Booking[] = [
  {id:'DEMO-1048',customer:'Sample customer A',service:'Ride',route:'Airport → Osu',fare:85,status:'completed',day:0},
  {id:'DEMO-1047',customer:'Sample customer B',service:'Delivery',route:'East Legon → Cantonments',fare:45,status:'active',day:0},
  {id:'DEMO-1046',customer:'Sample customer C',service:'Moving',route:'Tema → Spintex',fare:320,status:'scheduled',day:1},
  {id:'DEMO-1045',customer:'Sample customer D',service:'Ride',route:'Adenta → Accra Central',fare:110,status:'completed',day:2},
  {id:'DEMO-1044',customer:'Sample customer E',service:'Towing',route:'Madina → Workshop',fare:240,status:'completed',day:4},
  {id:'DEMO-1043',customer:'Sample customer F',service:'Delivery',route:'Osu → Labone',fare:35,status:'completed',day:6},
  {id:'DEMO-1042',customer:'Sample customer G',service:'Ride',route:'Tema → Airport',fare:150,status:'completed',day:12},
  {id:'DEMO-1041',customer:'Sample customer H',service:'Moving',route:'Accra → Tema',fare:480,status:'completed',day:40},
];
export class FixtureDashboardRepository implements DashboardRepository {
  async bookings(filters: DashboardFilters) {
    return fixtures.filter(row => row.day < filters.days && (filters.service === 'All' || row.service === filters.service));
  }
}
export function summarize(rows: readonly Booking[]) {
  return { bookings: rows.length, customers: new Set(rows.map(row => row.customer)).size,
    live: rows.filter(row => row.status === 'active').length,
    completed: rows.filter(row => row.status === 'completed').length };
}
