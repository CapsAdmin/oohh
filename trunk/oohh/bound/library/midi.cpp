#include "oohh.hpp"
#include <Windows.h>
#include <Mmsystem.h>

struct MIDIEvent
{
	unsigned char opcode;
	unsigned char channel;
	unsigned char data1;
	unsigned char data2;
	unsigned long time;
};

struct MIDIDevice
{
	union
	{
		HMIDIIN in;
		HMIDIOUT out;
	} handle;
	std::queue<MIDIEvent*> events;
	std::queue<MIDIEvent*> output_events;
	UINT id;
	bool output;
	HANDLE thread;
	HANDLE thread_event;
	CRITICAL_SECTION lock;
};

void CALLBACK MidiInProc(HMIDIIN hMidiIn, UINT wMsg, DWORD_PTR dwInstance, DWORD_PTR dwParam1, DWORD_PTR dwParam2)
{
	MIDIDevice* device = reinterpret_cast<MIDIDevice*>(dwInstance);

	if(wMsg == MIM_DATA)
	{
		MIDIEvent* event = new MIDIEvent;

		event->channel = dwParam1 >> 0 & 0x0f;
		event->opcode = dwParam1 >> 4 & 0x07;
		event->data1 = dwParam1 >> 8 & 0x7f;
		event->data2 = dwParam1 >> 16 & 0x7f;
		event->time = dwParam2;

		EnterCriticalSection(&device->lock);
		device->events.push(event);
		LeaveCriticalSection(&device->lock);
	}
}

static DWORD WINAPI ThreadProc(LPVOID lpParameter)
{
	MIDIDevice* device = reinterpret_cast<MIDIDevice*>(lpParameter);

	while(WaitForSingleObject(device->thread_event, INFINITE) == WAIT_OBJECT_0)
	{
		EnterCriticalSection(&device->lock);

		while(!device->output_events.empty())
		{
			MIDIEvent* event = device->output_events.front();
			midiOutShortMsg(device->handle.out, (event->channel & 0x0F) << 0 | (event->opcode & 0x07) << 4 | 0x80 | (event->data1 & 0x7F) << 8 | (event->data2 & 0x7F) << 16);
			device->output_events.pop();
		}

		LeaveCriticalSection(&device->lock);
	}

	return 0;
}

MIDIDevice *devices[2][50];

LUALIB_FUNCTION(midi, OpenInput)
{
	UINT id = -1;
	MMRESULT result;
	MIDIDevice *self;
	UINT device_count = midiInGetNumDevs();

	if(my->IsNumber(1))
	{
		id = (UINT)my->ToNumber(1) - 1;
	}
	else if(my->IsString(1))
	{
		const char* name = my->ToString(1);

		for(UINT i = 0; i < device_count; ++i)
		{
			MIDIINCAPS caps;
			midiInGetDevCaps(i, &caps, sizeof(caps));

			if(stricmp(caps.szPname, name) == 0)
			{
				id = i;
				break;
			}
		}
	}
	else
	{
		luaL_argerror(L, 1, "Needs to be a number or a string");
	}
	
	UINT out;

	if (devices[0][id] && midiInGetID(devices[0][id]->handle.in, &out) == MMSYSERR_NOERROR)
	{
		my->Push(devices[0][id]);

		return 1;
	}

	self = new MIDIDevice;
	result = midiInOpen(&self->handle.in, id, (DWORD_PTR)&MidiInProc, (DWORD_PTR)self, CALLBACK_FUNCTION);

	if(result != MMSYSERR_NOERROR)
	{
		delete self;

		char text[256];
		midiInGetErrorTextA(result, text, sizeof(text));

		lua_pushnil(L);
		my->Push(text);

		return 2;
	}

	self->output = false;
	self->id = id;

	InitializeCriticalSection(&self->lock);
	midiInStart(self->handle.in);

	devices[0][id] = self;
	my->Push(self);

	return 1;
}

LUALIB_FUNCTION(midi, OpenOutput)
{
	UINT id = -1;
	MMRESULT result;
	MIDIDevice* self;
	UINT device_count = midiOutGetNumDevs();

	if(my->IsNumber(1))
	{
		id = (UINT)my->ToNumber(1) - 1;
	}
	else if(my->IsString(1))
	{
		const char* name = my->ToString(1);

		for(UINT i = 0; i < device_count; ++i)
		{
			MIDIOUTCAPS caps;
			midiOutGetDevCaps(i, &caps, sizeof(caps));

			if(stricmp(caps.szPname, name) == 0)
			{
				id = i;
				break;
			}
		}
	}
	else
	{
		luaL_argerror(L, 1, "Needs to be a number or a string");
	}
	
	UINT out;

	if (devices[1][id] && midiOutGetID(devices[1][id]->handle.out, &out) == MMSYSERR_NOERROR)
	{
		my->Push(devices[1][id]);

		return 1;
	}

	self = new MIDIDevice;
	result = midiOutOpen(&self->handle.out, id, NULL, NULL, 0);

	if(result != MMSYSERR_NOERROR)
	{
		delete self;

		char text[256];
		midiOutGetErrorTextA(result, text, sizeof(text));

		lua_pushnil(L);
		my->Push(text);

		return 2;
	}

	self->output = true;
	self->id = id;

	self->thread_event = CreateEvent(NULL, FALSE, FALSE, NULL);
	self->thread = CreateThread(NULL, 0, &ThreadProc, self, 0, NULL);

	InitializeCriticalSection(&self->lock);

	devices[1][id] = self;
	my->Push(self);

	return 1;
}

LUALIB_FUNCTION(midi, GetInputs)
{
	UINT count = midiInGetNumDevs();
	my->NewTable();

	for(UINT i = 0; i < count; ++i)
	{
		MIDIINCAPS caps;
		midiInGetDevCaps(i, &caps, sizeof(caps));
		my->SetMember(-1, i + 1, caps.szPname);

	}

	return 1;
}

LUALIB_FUNCTION(midi, GetOutputs)
{
	UINT count = midiOutGetNumDevs();
	my->NewTable();

	for(UINT i = 0; i < count; ++i)
	{
		MIDIOUTCAPS caps;
		midiOutGetDevCaps(i, &caps, sizeof(caps));
		my->SetMember(-1, i + 1, caps.szPname);

	}

	return 1;
}

LUALIB_FUNCTION(midi, Update)
{
	for (UINT i = 0; i < 50; ++i)
	{
		auto self = devices[1][i];

		if(self)
		{
			SetEvent(self->thread_event);
		}
	}

	for (UINT i = 0; i < 50; ++i)
	{
		auto self = devices[0][i];

		if(self)
		{
			EnterCriticalSection(&self->lock);

			while(!self->events.empty())
			{
				MIDIEvent* i = self->events.front();

				my->CallEntityHook(self, "OnReceive", i->opcode, i->channel, i->data1, i->data2, i->time / 1000.0);

				self->events.pop();
			}

			LeaveCriticalSection(&self->lock);
		}
	}

	return 0;
}

LUAMTA_FUNCTION(device, IsOutput)
{
	auto self = my->ToMIDIDevice(1);

	my->Push(self->output);

	return 1;
}

LUAMTA_FUNCTION(device, Reset)
{
	auto self = my->ToMIDIDevice(1);

	if(self->output)
	{
		midiOutReset(self->handle.out);
	}
	else
	{
		midiInStop(self->handle.in);
		midiInReset(self->handle.in);
		midiInStart(self->handle.in);
	}

	return 0;
}

LUAMTA_FUNCTION(device, IsValid)
{
	auto self = my->ToMIDIDevice(1);

	UINT out;

	my->Push(midiInGetID(self->handle.in, &out) == MMSYSERR_NOERROR);

	return 1;
}

LUAMTA_FUNCTION(device, Close)
{
	auto device = my->ToMIDIDevice(1);

	if(device->output)
	{
		EnterCriticalSection(&device->lock);

		while(!device->output_events.empty())
		{
			delete device->output_events.front();
			device->output_events.pop();
		}

		LeaveCriticalSection(&device->lock);

		midiOutReset(device->handle.out);
		midiOutClose(device->handle.out);


		CloseHandle(device->thread_event);
		CloseHandle(device->thread);
	}
	else
	{
		EnterCriticalSection(&device->lock);

		while(!device->events.empty())
		{
			delete device->events.front();
			device->events.pop();
		}

		LeaveCriticalSection(&device->lock);

		midiInStop(device->handle.in);
		midiInReset(device->handle.in);
		midiInClose(device->handle.in);
	}

	DeleteCriticalSection(&device->lock);

	devices[device->output ? 1 : 0][device->id] = nullptr;

	return 0;
}

LUAMTA_FUNCTION(device, Send)
{
	auto self = my->ToMIDIDevice(1);

	if(!self->output)
	{
		return 0;
	}

	unsigned opcode = my->ToNumber(2);
	unsigned channel = my->ToNumber(3, 0);
	unsigned data1 = my->ToNumber(4, 0);
	unsigned data2 = my->ToNumber(5, 0);

	MIDIEvent* event = new MIDIEvent;
	event->opcode = opcode;
	event->channel = channel;
	event->data1 = data1;
	event->data2 = data2;
	event->time = 0;

	EnterCriticalSection(&self->lock);
	self->output_events.push(event);
	LeaveCriticalSection(&self->lock);

	return 0;
}