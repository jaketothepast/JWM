#pragma once
#include <Window.hh>
#include <PlatformWin32.hh>
#include <functional>
#include <utility>
#include <atomic>
#include <bitset>
#include <vector>
#include <mutex>
#include <jni.h>

namespace jwm {
    class WindowWin32 final: public Window {
    public:
        enum class Event {
            SwitchContext,
            SwapBuffers,
            EnableVsync,
            DisableVsync,
            Destroyed
        };

        enum class Flag: size_t {
            EnterSizeMove = 1,
            RequestFrame = 2,
            HasAttachedLayer = 3,
            RecreateForNextLayer = 4,
            IgnoreMessages = 5,
            Max = 6
        };

        using Callback = std::function<void(Event)>;
        static const int BUTTON_DOWN = 0x8000;
        static const UINT HIGH_SURROGATE_L = 0xd800;
        static const UINT HIGH_SURROGATE_U = 0xdbff;
        static const UINT LOW_SURROGATE_L = 0xdc00;
        static const UINT LOW_SURROGATE_U = 0xdfff;

    public:
        explicit WindowWin32(JNIEnv* env, class WindowManagerWin32& windowManagerWin32);
        ~WindowWin32() override;
        bool init();
        void recreate();
        void start();
        void show();
        void getPosition(int& left, int& top) const;
        void getSize(int& width, int& height) const;
        void getClientAreaSize(int& width, int& height) const;
        int getLeft() const;
        int getTop() const;
        int getWidth() const;
        int getHeight() const;
        float getScale() const;
        void move(int left, int top);
        void resize(int width, int height);
        void enqueueCallback(jobject callback);
        void requestClose();
        LRESULT processEvent(UINT uMsg, WPARAM wParam, LPARAM lParam);

    public:
        int addEventListener(Callback callback);
        void removeEventListener(int callbackID);
        void notifyEvent(Event event);
        void setFlag(Flag flag) { _flags.set(static_cast<size_t>(flag), true); }
        void removeFlag(Flag flag) { _flags.set(static_cast<size_t>(flag), false); }
        bool testFlag(Flag flag) { return _flags.test(static_cast<size_t>(flag)); }
        JNIEnv* getJNIEnv() const { return fEnv; }
        HWND getHWnd() const { return _hWnd; }

    private:
        DWORD _getWindowStyle() const;
        DWORD _getWindowExStyle() const;
        int _getModifiers() const;
        int _getMouseButtons() const;
        int _getNextCallbackID();
        void _toUtf8(unsigned int codepoint, char* text);
        void _setFrameTimer();
        void _killFrameTimer();
        bool _createInternal(int x, int y, int w, int h, const wchar_t* caption);
        void _destroyInternal();
        void _close();

    private:
        friend class WindowManagerWin32;

        std::vector<std::pair<int, Callback>> _eventListeners;
        std::vector<jobject> _callbacks;
        std::bitset<static_cast<size_t>(Flag::Max)> _flags;
        std::atomic_bool _shouldClose{false};

        class WindowManagerWin32& _windowManager;

        HWND _hWnd = nullptr;
        int _nextCallbackID = 0;
        wchar_t _highSurrogate = 0;

        mutable std::mutex _accessMutex;
    };
}