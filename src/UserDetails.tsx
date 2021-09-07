export interface UserDetails {
  id: string;
  first_name: string;
  dob: string | '08-Aug-1997';
  weight: string;
  height: string;
  gender: string;
  deviceType: string;
}

export interface WScaleUser {
  key: String;
  value: String;
}
